import Foundation
import OSLog
import Observation

enum ConnectionState: Sendable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var statusText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
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
    var mcpSessionId: String?
    var gameSessionId: String?

    var isConnected: Bool { connectionState.isConnected }

    func connect(username: String, password: String) async {
        SMLog.auth.info("Starting connection for user: \(username)")
        connectionState = .connecting

        do {
            SMLog.auth.info("Step 1/3: Initializing MCP session...")
            let mcpId = try await MCPClient.initialize()
            mcpSessionId = mcpId
            SMLog.auth.info("Step 1/3 complete: MCP session \(mcpId.prefix(20))...")

            SMLog.auth.info("Step 2/3: Sending initialized notification...")
            try await MCPClient.sendInitialized(mcpSessionId: mcpId)
            SMLog.auth.info("Step 2/3 complete")

            SMLog.auth.info("Step 3/3: Logging in...")
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
            let loginResponse: LoginResponse
            do {
                loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            } catch {
                SMLog.decode.error("Failed to decode login response: \(error)")
                if let raw = String(data: data.prefix(500), encoding: .utf8) {
                    SMLog.decode.debug("Login raw response: \(raw)")
                }
                throw error
            }
            gameSessionId = loginResponse.session_id
            connectionState = .connected
            SMLog.auth.info("Step 3/3 complete: game session \(loginResponse.session_id.prefix(20))...")
            SMLog.auth.info("Connection established successfully")
        } catch {
            SMLog.auth.error("Connection failed: \(error.localizedDescription)")
            connectionState = .error(error.localizedDescription)
        }
    }

    func disconnect() {
        SMLog.auth.info("Disconnecting (mcp: \(self.mcpSessionId?.prefix(12) ?? "nil", privacy: .public), game: \(self.gameSessionId?.prefix(12) ?? "nil", privacy: .public))")
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
