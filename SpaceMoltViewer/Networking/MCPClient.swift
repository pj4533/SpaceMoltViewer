import Foundation
import OSLog

enum MCPError: Error, LocalizedError {
    case noSessionId
    case invalidResponse
    case serverError(code: Int, message: String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .noSessionId:
            return "Server did not return a session ID"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingError(let detail):
            return "Decoding error: \(detail)"
        }
    }
}

struct MCPClient {
    static let baseURL = URL(string: "https://game.spacemolt.com/mcp")!
    private static var requestId = 0

    private static func nextId() -> Int {
        requestId += 1
        return requestId
    }

    private static func makeRequest(mcpSessionId: String? = nil) -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
        if let mcpSessionId {
            request.setValue(mcpSessionId, forHTTPHeaderField: "Mcp-Session-Id")
        }
        return request
    }

    static func initialize() async throws -> String {
        let id = nextId()
        SMLog.network.info("MCP initialize request (id: \(id))")

        var request = makeRequest()
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "initialize",
            "params": [
                "protocolVersion": "2024-11-05",
                "capabilities": [String: Any](),
                "clientInfo": ["name": "drift-viewer", "version": "1.0"]
            ] as [String: Any],
            "id": id
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            SMLog.network.error("MCP initialize: response is not HTTPURLResponse")
            throw MCPError.noSessionId
        }

        SMLog.network.debug("MCP initialize: HTTP \(httpResponse.statusCode)")

        guard let sessionId = httpResponse.value(forHTTPHeaderField: "mcp-session-id") else {
            SMLog.network.error("MCP initialize: no mcp-session-id header in response")
            throw MCPError.noSessionId
        }

        SMLog.network.info("MCP session initialized: \(sessionId.prefix(20))...")
        return sessionId
    }

    static func sendInitialized(mcpSessionId: String) async throws {
        SMLog.network.info("Sending notifications/initialized")

        var request = makeRequest(mcpSessionId: mcpSessionId)
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "notifications/initialized"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            SMLog.network.debug("notifications/initialized: HTTP \(httpResponse.statusCode)")
        }
    }

    static func callTool(name: String, arguments: [String: Any], mcpSessionId: String) async throws -> Data {
        let id = nextId()
        SMLog.network.debug("Tool call: \(name) (id: \(id))")

        var request = makeRequest(mcpSessionId: mcpSessionId)
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": [
                "name": name,
                "arguments": arguments
            ] as [String: Any],
            "id": id
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let startTime = CFAbsoluteTimeGetCurrent()
        let (data, response) = try await URLSession.shared.data(for: request)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        if let httpResponse = response as? HTTPURLResponse {
            SMLog.network.debug("Tool \(name): HTTP \(httpResponse.statusCode), \(data.count) bytes, \(String(format: "%.2f", elapsed))s")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            SMLog.network.error("Tool \(name): response is not a JSON object")
            throw MCPError.invalidResponse
        }

        if let error = json["error"] as? [String: Any] {
            let code = error["code"] as? Int ?? -1
            let message = error["message"] as? String ?? "Unknown error"
            SMLog.network.error("Tool \(name): server error (\(code)): \(message)")
            throw MCPError.serverError(code: code, message: message)
        }

        guard let result = json["result"] as? [String: Any],
              let content = result["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            SMLog.network.error("Tool \(name): could not extract result.content[0].text")
            throw MCPError.invalidResponse
        }

        guard let innerData = text.data(using: .utf8) else {
            SMLog.network.error("Tool \(name): could not convert response text to UTF-8 data")
            throw MCPError.decodingError("Could not convert response text to data")
        }

        SMLog.network.debug("Tool \(name): decoded \(innerData.count) bytes of inner JSON")
        return innerData
    }
}
