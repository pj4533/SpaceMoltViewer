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
    var connectionState: ConnectionState = .disconnected

    // WebSocket for real-time push events
    var webSocketClient: WebSocketClient?

    // MCP session for data queries via GameAPI
    var mcpSessionId: String?
    var gameSessionId: String?

    var isConnected: Bool { connectionState.isConnected }

    func connect(username: String, password: String) async {
        SMLog.auth.info("Starting connection for user: \(username)")
        connectionState = .connecting

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
            let session_id: String
        }
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        gameSessionId = loginResponse.session_id
        SMLog.auth.info("MCP: session established")
    }

    func disconnect() {
        SMLog.auth.info("Disconnecting")
        if let client = webSocketClient {
            Task { await client.disconnect() }
        }
        webSocketClient = nil
        mcpSessionId = nil
        gameSessionId = nil
        connectionState = .disconnected
        SMLog.auth.info("Disconnected")
    }

    func reconnect(username: String, password: String) async {
        SMLog.auth.info("Reconnecting...")
        disconnect()
        await connect(username: username, password: password)
    }
}
