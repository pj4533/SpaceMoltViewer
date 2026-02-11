import Foundation
import OSLog

enum GameAPIError: Error, LocalizedError {
    case disallowedTool(String)
    case notConnected

    var errorDescription: String? {
        switch self {
        case .disallowedTool(let name):
            return "Tool '\(name)' is not in the safety whitelist"
        case .notConnected:
            return "Not connected to game server"
        }
    }
}

struct GameAPI {
    private static let allowedTools: Set<String> = [
        "get_status", "get_cargo", "get_system", "get_nearby",
        "get_ship", "get_skills", "get_active_missions",
        "get_poi", "list_ships",
        "captains_log_list", "captains_log_get", "get_chat_history",
        "get_base", "get_listings", "view_market",
        "estimate_purchase", "get_trades", "view_storage",
        "get_wrecks", "get_base_wrecks", "raid_status",
        "get_missions", "find_route", "search_systems",
        "get_recipes", "get_ships", "get_notes", "read_note",
        "faction_info", "faction_list", "faction_get_invites",
        "claim_insurance", "get_base_cost", "get_version", "get_commands"
    ]

    let sessionManager: SessionManager

    private func call<T: Decodable>(tool: String, extraArgs: [String: Any] = [:]) async throws -> T {
        guard Self.allowedTools.contains(tool) else {
            SMLog.api.fault("BLOCKED: attempted call to disallowed tool '\(tool)'")
            throw GameAPIError.disallowedTool(tool)
        }
        guard let mcpSessionId = sessionManager.mcpSessionId,
              let gameSessionId = sessionManager.gameSessionId else {
            SMLog.api.warning("Call to \(tool) while not connected")
            throw GameAPIError.notConnected
        }

        var args = extraArgs
        args["session_id"] = gameSessionId

        SMLog.api.debug("Calling \(tool)")
        let data = try await MCPClient.callTool(
            name: tool,
            arguments: args,
            mcpSessionId: mcpSessionId
        )

        do {
            let result = try JSONDecoder().decode(T.self, from: data)
            SMLog.api.debug("\(tool) decoded successfully as \(String(describing: T.self))")
            return result
        } catch {
            SMLog.decode.error("\(tool) decode failed for \(String(describing: T.self)): \(error)")
            if let jsonString = String(data: data.prefix(500), encoding: .utf8) {
                SMLog.decode.debug("\(tool) raw response (first 500 chars): \(jsonString)")
            }
            throw error
        }
    }

    // MARK: - High Frequency

    func getStatus() async throws -> PlayerStatusResponse {
        try await call(tool: "get_status")
    }

    func getCargo() async throws -> CargoResponse {
        try await call(tool: "get_cargo")
    }

    // MARK: - Medium Frequency

    func getSystem() async throws -> SystemResponse {
        try await call(tool: "get_system")
    }

    func getNearby() async throws -> NearbyResponse {
        try await call(tool: "get_nearby")
    }

    func getActiveMissions() async throws -> MissionsResponse {
        try await call(tool: "get_active_missions")
    }

    func getChatHistory(channel: String, limit: Int = 50) async throws -> ChatHistoryResponse {
        SMLog.api.debug("get_chat_history channel=\(channel) limit=\(limit)")
        return try await call(tool: "get_chat_history", extraArgs: ["channel": channel, "limit": limit])
    }

    // MARK: - Low Frequency

    func getShip() async throws -> ShipDetailResponse {
        try await call(tool: "get_ship")
    }

    func getSkills() async throws -> SkillsResponse {
        try await call(tool: "get_skills")
    }

    func listShips() async throws -> OwnedShipsResponse {
        try await call(tool: "list_ships")
    }

    func viewStorage() async throws -> StorageResponse {
        try await call(tool: "view_storage")
    }

    // MARK: - On Demand

    func getCaptainsLog() async throws -> CaptainsLogResponse {
        try await call(tool: "captains_log_list")
    }

    // MARK: - Public API (no auth needed)

    static func fetchPublicMap() async throws -> [MapSystem] {
        let url = URL(string: "https://game.spacemolt.com/api/map")!
        SMLog.api.info("Fetching public galaxy map from \(url)")
        let startTime = CFAbsoluteTimeGetCurrent()
        let (data, response) = try await URLSession.shared.data(from: url)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        if let httpResponse = response as? HTTPURLResponse {
            SMLog.api.info("Public map: HTTP \(httpResponse.statusCode), \(data.count) bytes, \(String(format: "%.2f", elapsed))s")
        }

        do {
            let wrapper = try JSONDecoder().decode(PublicMapResponse.self, from: data)
            SMLog.api.info("Public map decoded: \(wrapper.systems.count) systems")
            return wrapper.systems
        } catch {
            SMLog.decode.error("Failed to decode public map: \(error)")
            if let raw = String(data: data.prefix(500), encoding: .utf8) {
                SMLog.decode.debug("Public map raw response (first 500 chars): \(raw)")
            }
            throw error
        }
    }
}
