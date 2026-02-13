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

        // Build decode attempts:
        // 1. Direct decode
        // 2. Round-trip through JSONSerialization (ObjC parser handles floats the Swift parser rejects)
        // 3. Regex sanitization (truncate excessive decimal precision)
        var attempts: [(String, Data)] = [("direct", data)]

        if let normalized = Self.normalizeJSON(data) {
            attempts.append(("normalized", normalized))
        }

        let sanitized = Self.sanitizeFloatingPoint(data)
        if sanitized != data {
            attempts.append(("sanitized", sanitized))
        }

        for (index, (label, payload)) in attempts.enumerated() {
            do {
                let result = try JSONDecoder().decode(T.self, from: payload)
                if index > 0 {
                    SMLog.api.debug("\(tool) decoded as \(String(describing: T.self)) (after \(label))")
                } else {
                    SMLog.api.debug("\(tool) decoded successfully as \(String(describing: T.self))")
                }
                return result
            } catch {
                if index < attempts.count - 1 {
                    SMLog.decode.debug("\(tool): \(label) decode failed, trying next approach")
                    continue
                }
                // All attempts failed — detailed logging
                Self.logDecodeFailure(tool: tool, type: T.self, error: error, data: data)
                throw error
            }
        }
        fatalError("Unreachable")
    }

    /// Normalize JSON by round-tripping through JSONSerialization (ObjC parser).
    /// Handles floating-point numbers that Swift's Foundation JSON parser rejects (e.g. "5.29").
    private static func normalizeJSON(_ data: Data) -> Data? {
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
              let normalized = try? JSONSerialization.data(withJSONObject: obj) else {
            return nil
        }
        return normalized
    }

    /// Reformat floating-point numbers that Swift's JSON parser rejects.
    /// Some numbers (e.g. 9.49) trigger "not representable in Swift" errors.
    /// Converting to scientific notation (e.g. 9.49e0) bypasses the parser bug.
    private static func sanitizeFloatingPoint(_ data: Data) -> Data {
        guard let json = String(data: data, encoding: .utf8) else { return data }
        guard let regex = try? NSRegularExpression(pattern: #"-?\d+\.\d+"#) else { return data }
        let mutable = NSMutableString(string: json)
        let matches = regex.matches(in: json, range: NSRange(json.startIndex..., in: json))
        for match in matches.reversed() {
            let numStr = mutable.substring(with: match.range)
            if Double(numStr) != nil {
                // Append e0 to force scientific notation parsing path
                mutable.replaceCharacters(in: match.range, with: numStr + "e0")
            }
        }
        return (mutable as String).data(using: .utf8) ?? data
    }

    /// Log detailed information about a decode failure
    private static func logDecodeFailure(tool: String, type: Any.Type, error: Error, data: Data) {
        SMLog.decode.error("\(tool) all decode attempts failed for \(String(describing: type))")

        if let jsonString = String(data: data, encoding: .utf8) {
            let previewLen = min(jsonString.count, 2000)
            let preview = String(jsonString.prefix(previewLen))
            SMLog.decode.error("\(tool) raw response (\(data.count) bytes, first \(previewLen) chars):\n\(preview)")
        }

        switch error {
        case DecodingError.dataCorrupted(let ctx):
            let path = ctx.codingPath.map { $0.stringValue }.joined(separator: ".")
            SMLog.decode.error("\(tool) dataCorrupted at '\(path.isEmpty ? "root" : path)': \(ctx.debugDescription)")
            if let underlying = ctx.underlyingError {
                SMLog.decode.error("\(tool) underlying: \(underlying)")
            }
        case DecodingError.typeMismatch(let expectedType, let ctx):
            let path = ctx.codingPath.map { $0.stringValue }.joined(separator: ".")
            SMLog.decode.error("\(tool) typeMismatch at '\(path)': expected \(expectedType), \(ctx.debugDescription)")
        case DecodingError.keyNotFound(let key, let ctx):
            let path = ctx.codingPath.map { $0.stringValue }.joined(separator: ".")
            SMLog.decode.error("\(tool) keyNotFound '\(key.stringValue)' at '\(path)': \(ctx.debugDescription)")
        case DecodingError.valueNotFound(let expectedType, let ctx):
            let path = ctx.codingPath.map { $0.stringValue }.joined(separator: ".")
            SMLog.decode.error("\(tool) valueNotFound at '\(path)': expected \(expectedType), \(ctx.debugDescription)")
        default:
            SMLog.decode.error("\(tool) error: \(error)")
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

    func getPoi(id poiId: String) async throws -> PoiDetailResponse {
        try await call(tool: "get_poi", extraArgs: ["poi_id": poiId])
    }

    // MARK: - On Demand

    func getCaptainsLogPage(index: Int = 0) async throws -> CaptainsLogPageResponse {
        try await call(tool: "captains_log_list", extraArgs: ["index": index])
    }

    func getCaptainsLog() async throws -> CaptainsLogResponse {
        // Fetch first page to get total count
        let first = try await getCaptainsLogPage(index: 0)
        var entries = [first.entry]

        // Fetch remaining entries
        for i in 1..<min(first.totalCount, first.maxEntries) {
            let page = try await getCaptainsLogPage(index: i)
            entries.append(page.entry)
        }

        return CaptainsLogResponse(
            entries: entries,
            totalCount: first.totalCount,
            maxEntries: first.maxEntries
        )
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
