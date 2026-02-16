import Foundation
import OSLog
import Observation

enum ConnectionState: Sendable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error(String)

    var statusText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .reconnecting: return "Reconnecting..."
        case .error(let msg): return "Error: \(msg)"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

@Observable
class SessionManager {
    private(set) var connectionState: ConnectionState = .disconnected

    // WebSocket for real-time push events
    private(set) var webSocketClient: WebSocketClient?

    // MCP session for data queries via GameAPI
    private(set) var mcpSessionId: String?
    private(set) var gameSessionId: String?

    // Saved credentials for MCP re-initialization after reconnect
    private var savedUsername: String?
    private var savedPassword: String?

    // Prevents multiple concurrent MCP re-initializations
    private var mcpReinitTask: Task<Void, Error>?

    var isConnected: Bool { connectionState.isConnected }

    func connect(username: String, password: String) async {
        SMLog.auth.info("Starting connection for user: \(username)")
        connectionState = .connecting

        // Save credentials for MCP re-initialization on reconnect
        savedUsername = username
        savedPassword = password

        do {
            // Connect WebSocket and MCP in parallel
            async let wsResult = connectWebSocket(username: username, password: password)
            async let mcpResult = connectMCP(username: username, password: password)

            let (wsClient, _) = try await (wsResult, mcpResult)
            webSocketClient = wsClient

            connectionState = .connected
            SMLog.auth.info("Connection established (WebSocket + MCP)")
        } catch {
            SMLog.auth.error("Connection failed: \(error.localizedDescription)")
            connectionState = .error(error.localizedDescription)
            webSocketClient = nil
            mcpSessionId = nil
            gameSessionId = nil
        }
    }

    private func connectWebSocket(username: String, password: String) async throws -> WebSocketClient {
        SMLog.auth.info("WebSocket: connecting...")
        let client = WebSocketClient()
        client.connectionStateHandler = { [weak self] state in
            Task { @MainActor in
                self?.connectionState = state
                // Re-initialize MCP session after WebSocket reconnection
                if case .connected = state {
                    await self?.reinitializeMCP()
                }
            }
        }
        _ = try await client.connect()
        _ = try await client.login(username: username, password: password)
        await client.enableReconnect()
        SMLog.auth.info("WebSocket: connected and logged in")
        return client
    }

    private func connectMCP(username: String, password: String) async throws {
        SMLog.auth.info("MCP: initializing session...")
        let mcpId = try await MCPClient.initialize()
        mcpSessionId = mcpId
        try await MCPClient.sendInitialized(mcpSessionId: mcpId)

        let loginArgs: [String: Any] = [
            "username": username,
            "password": password
        ]
        let data = try await MCPClient.callTool(
            name: "login",
            arguments: loginArgs,
            mcpSessionId: mcpId
        )

        struct LoginResponse: Decodable {
            let sessionId: String
            enum CodingKeys: String, CodingKey {
                case sessionId = "session_id"
            }
        }
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        gameSessionId = loginResponse.sessionId
        SMLog.auth.info("MCP: session established")
    }

    private func reinitializeMCP() async {
        guard let username = savedUsername, let password = savedPassword else {
            SMLog.auth.error("Cannot re-initialize MCP: no saved credentials")
            return
        }

        SMLog.auth.info("Re-initializing MCP session after reconnect...")
        do {
            try await connectMCP(username: username, password: password)
            SMLog.auth.info("MCP session re-initialized successfully")
        } catch {
            SMLog.auth.error("Failed to re-initialize MCP session: \(error.localizedDescription)")
        }
    }

    /// Re-initialize the MCP session (e.g. after session expiry error -32600).
    /// Coalesces concurrent calls so only one re-init runs at a time.
    func ensureMCPSession() async throws {
        if let existing = mcpReinitTask {
            // Another re-init is already in progress — wait for it
            try await existing.value
            return
        }

        let task = Task {
            defer { mcpReinitTask = nil }

            guard let username = savedUsername, let password = savedPassword else {
                throw GameAPIError.notConnected
            }

            SMLog.auth.info("MCP session expired, re-initializing...")
            try await connectMCP(username: username, password: password)
            SMLog.auth.info("MCP session re-initialized after expiry")
        }
        mcpReinitTask = task
        try await task.value
    }

    func disconnect() async {
        SMLog.auth.info("Disconnecting")
        if let client = webSocketClient {
            await client.shutdown()
        }
        webSocketClient = nil
        mcpSessionId = nil
        gameSessionId = nil
        savedUsername = nil
        savedPassword = nil
        connectionState = .disconnected
        SMLog.auth.info("Disconnected")
    }

    func reconnect(username: String, password: String) async {
        SMLog.auth.info("Reconnecting...")
        await disconnect()
        await connect(username: username, password: password)
    }
}
