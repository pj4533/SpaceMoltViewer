import Foundation
import OSLog

enum WebSocketError: Error, LocalizedError {
    case notConnected
    case connectionFailed(String)
    case loginFailed(String)
    case encodingError

    var errorDescription: String? {
        switch self {
        case .notConnected: return "WebSocket is not connected"
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .loginFailed(let msg): return "Login failed: \(msg)"
        case .encodingError: return "Failed to encode message"
        }
    }
}

struct WSRawMessage: Sendable {
    let type: String
    let payloadData: Data
}

/// WebSocket client for receiving real-time push events from the game server.
/// Data queries use the MCP HTTP API via GameAPI — WebSocket is push-only.
final class WebSocketClient: Sendable {
    private let wsURL = URL(string: "wss://game.spacemolt.com/ws")!

    private let state = ClientState()

    /// Public message stream for push events (state_update, ok, chat_message, etc.)
    nonisolated let messages: AsyncStream<WSRawMessage>
    private let messageContinuation: AsyncStream<WSRawMessage>.Continuation

    init() {
        let (stream, continuation) = AsyncStream<WSRawMessage>.makeStream(bufferingPolicy: .bufferingNewest(200))
        messages = stream
        messageContinuation = continuation
    }

    var isConnected: Bool {
        get async { await state.isConnected }
    }

    // MARK: - Connection

    func connect() async throws -> WelcomePayload {
        SMLog.websocket.info("Connecting to \(self.wsURL)")

        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: wsURL)
        task.resume()

        await state.setTask(task)
        await state.setConnected(true)

        // Start receive loop
        let receiveTask = Task { [weak self] in
            guard let self else { return }
            await self.receiveLoop()
        }
        await state.setReceiveTask(receiveTask)

        // Wait for welcome message
        SMLog.websocket.debug("Waiting for welcome message...")
        let welcomeData = try await waitForMessage(ofType: "welcome", timeout: 10)
        do {
            let welcome = try JSONDecoder().decode(WelcomePayload.self, from: welcomeData)
            SMLog.websocket.info("Welcome received: tick=\(welcome.currentTick ?? 0)")
            return welcome
        } catch {
            SMLog.websocket.error("Failed to decode welcome: \(error)")
            throw error
        }
    }

    func login(username: String, password: String) async throws -> Data {
        SMLog.websocket.info("Sending login for \(username)")

        await state.saveCredentials(username: username, password: password)

        let payload: [String: Any] = [
            "username": username,
            "password": password
        ]
        try await send(type: "login", payload: payload)

        let data = try await waitForMessage(ofType: "logged_in", timeout: 15)
        SMLog.websocket.info("Login successful")
        return data
    }

    func disconnect() async {
        SMLog.websocket.info("Disconnecting")
        await state.setShouldReconnect(false)
        await state.cancelReconnect()
        await state.cancelReceive()

        if let task = await state.webSocketTask {
            task.cancel(with: .goingAway, reason: nil)
        }

        await state.setTask(nil)
        await state.setConnected(false)
        await state.cancelAllWaiters()
        messageContinuation.finish()
        SMLog.websocket.info("Disconnected")
    }

    // MARK: - Private

    private func send(type: String, payload: [String: Any] = [:]) async throws {
        guard let task = await state.webSocketTask else {
            throw WebSocketError.notConnected
        }

        let message: [String: Any] = [
            "type": type,
            "payload": payload
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let string = String(data: data, encoding: .utf8) else {
            throw WebSocketError.encodingError
        }

        try await task.send(.string(string))
        SMLog.websocket.debug("Sent: \(type)")
    }

    private func waitForMessage(ofType expectedType: String, timeout: TimeInterval) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                await self.state.registerWaiter(type: expectedType, continuation: continuation)
            }
        }
    }

    private func receiveLoop() async {
        SMLog.websocket.debug("Receive loop started")

        while !Task.isCancelled {
            guard let task = await state.webSocketTask else { break }

            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    guard let data = text.data(using: .utf8) else { continue }
                    await handleRawMessage(data)
                case .data(let data):
                    await handleRawMessage(data)
                @unknown default:
                    break
                }
            } catch {
                if !Task.isCancelled {
                    SMLog.websocket.error("Receive error: \(error.localizedDescription)")
                    await handleDisconnect()
                }
                break
            }
        }

        SMLog.websocket.debug("Receive loop ended")
    }

    private func handleRawMessage(_ data: Data) async {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        // Extract payload data
        let payloadData: Data
        if let payload = json["payload"] {
            payloadData = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
        } else {
            payloadData = data
        }

        // Check for waiters (welcome, logged_in, reconnected)
        if await state.routeToWaiter(type: type, data: payloadData) {
            return
        }

        // Everything else is a push event — send to stream
        if type != "tick" {
            SMLog.websocket.debug("Push event: \(type)")
        }
        messageContinuation.yield(WSRawMessage(type: type, payloadData: payloadData))
    }

    private func handleDisconnect() async {
        let wasConnected = await state.isConnected
        await state.setConnected(false)

        guard wasConnected, await state.shouldReconnect else { return }

        SMLog.websocket.info("Unexpected disconnect, starting reconnection")
        await startReconnect()
    }

    // MARK: - Reconnection

    func enableReconnect() async {
        await state.setShouldReconnect(true)
    }

    private func startReconnect() async {
        let reconnectTask = Task { [weak self] in
            guard let self else { return }
            var attempt = 0
            let maxAttempts = 10

            while attempt < maxAttempts, !Task.isCancelled {
                attempt += 1
                let delay = min(Double(1 << min(attempt - 1, 5)), 30.0)
                SMLog.websocket.info("Reconnect attempt \(attempt)/\(maxAttempts) in \(delay)s")

                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { break }

                do {
                    _ = try await self.connect()

                    guard let (username, password) = await self.state.savedCredentials else {
                        SMLog.websocket.error("No saved credentials for reconnect")
                        break
                    }

                    _ = try await self.login(username: username, password: password)
                    await self.state.setShouldReconnect(true)
                    SMLog.websocket.info("Reconnected successfully")
                    return
                } catch {
                    SMLog.websocket.error("Reconnect attempt \(attempt) failed: \(error.localizedDescription)")
                }
            }

            SMLog.websocket.error("Reconnection failed after \(maxAttempts) attempts")
        }
        await state.setReconnectTask(reconnectTask)
    }
}

// MARK: - Actor for thread-safe state management

private actor ClientState {
    var webSocketTask: URLSessionWebSocketTask?
    var receiveTask: Task<Void, Never>?
    var reconnectTask: Task<Void, Never>?
    var isConnected = false
    var shouldReconnect = false

    private var savedUsername: String?
    private var savedPassword: String?

    // Waiters for specific message types (welcome, logged_in)
    private var messageWaiters: [String: CheckedContinuation<Data, Error>] = [:]

    func setTask(_ task: URLSessionWebSocketTask?) {
        webSocketTask = task
    }

    func setReceiveTask(_ task: Task<Void, Never>) {
        receiveTask?.cancel()
        receiveTask = task
    }

    func setReconnectTask(_ task: Task<Void, Never>) {
        reconnectTask?.cancel()
        reconnectTask = task
    }

    func setConnected(_ connected: Bool) {
        isConnected = connected
    }

    func setShouldReconnect(_ value: Bool) {
        shouldReconnect = value
    }

    func saveCredentials(username: String, password: String) {
        savedUsername = username
        savedPassword = password
    }

    var savedCredentials: (String, String)? {
        guard let u = savedUsername, let p = savedPassword else { return nil }
        return (u, p)
    }

    func cancelReceive() {
        receiveTask?.cancel()
        receiveTask = nil
    }

    func cancelReconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
    }

    // MARK: - Message Waiters

    func registerWaiter(type: String, continuation: CheckedContinuation<Data, Error>) {
        messageWaiters[type] = continuation
    }

    func routeToWaiter(type: String, data: Data) -> Bool {
        guard let cont = messageWaiters.removeValue(forKey: type) else { return false }
        cont.resume(returning: data)
        return true
    }

    func cancelAllWaiters() {
        for (_, cont) in messageWaiters {
            cont.resume(throwing: WebSocketError.notConnected)
        }
        messageWaiters.removeAll()
    }
}
