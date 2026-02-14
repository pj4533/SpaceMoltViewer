import Foundation
import OSLog
import Observation

@MainActor @Observable
class GameStateManager {
    let webSocketClient: WebSocketClient
    let gameAPI: GameAPI

    // Game state properties (read-only from views)
    private(set) var playerStatus: PlayerStatusResponse?
    private(set) var cargo: CargoResponse?
    private(set) var system: SystemResponse?
    private(set) var nearby: NearbyResponse?
    private(set) var missions: MissionsResponse?
    private(set) var chatMessages: ChatHistoryResponse?
    private(set) var storage: StorageResponse?
    private(set) var shipDetail: ShipDetailResponse?
    private(set) var skills: SkillsResponse?
    private(set) var ownedShips: OwnedShipsResponse?
    private(set) var publicMap: [MapSystem]?
    private(set) var captainsLog: CaptainsLogResponse?

    private(set) var poiResources: [String: [PoiResource]] = [:]

    private(set) var lastError: String?
    var isConnected: Bool { _isConnected }

    // WebSocket-driven properties
    private(set) var events: [GameEvent] = []
    private(set) var currentTick: Int?
    private(set) var inCombat: Bool = false
    private(set) var travelProgress: Double?
    private(set) var travelDestination: String?

    // Private
    private var _isConnected = false
    private var messageTask: Task<Void, Never>?
    private var mapTask: Task<Void, Never>?
    private var initialLoadTask: Task<Void, Never>?
    private var previousSystem: String?
    private static let maxEvents = 200

    // Throttling: track last refresh time per query type
    private var lastRefreshTime: [String: Date] = [:]
    private static let throttleIntervals: [String: TimeInterval] = [
        "get_skills": 10,
        "get_nearby": 5,
        "get_cargo": 5,
        "get_system": 5,
        "view_storage": 10,
        "get_ship": 10,
        "list_ships": 30,
    ]

    init(webSocketClient: WebSocketClient, gameAPI: GameAPI) {
        self.webSocketClient = webSocketClient
        self.gameAPI = gameAPI
        SMLog.websocket.debug("GameStateManager initialized")
    }

    func start() {
        SMLog.websocket.info("GameStateManager starting")
        _isConnected = true

        // Load public map (HTTP, not MCP)
        mapTask = Task {
            do {
                publicMap = try await GameAPI.fetchPublicMap()
                SMLog.websocket.info("Public map loaded: \(self.publicMap?.count ?? 0) systems")
            } catch {
                SMLog.websocket.error("Failed to load public map: \(error.localizedDescription)")
            }
        }

        // Start processing WebSocket push events
        messageTask = Task { [weak self] in
            guard let self else { return }
            for await message in self.webSocketClient.messages {
                guard !Task.isCancelled else { break }
                self.handleMessage(message)
            }
            SMLog.websocket.debug("Message processing loop ended")
        }

        // Load initial data via MCP API
        initialLoadTask = Task { await loadInitialData() }
    }

    func stop() {
        SMLog.websocket.info("GameStateManager stopping")
        messageTask?.cancel()
        messageTask = nil
        mapTask?.cancel()
        mapTask = nil
        initialLoadTask?.cancel()
        initialLoadTask = nil
        _isConnected = false
    }

    // MARK: - Initial Data Load (MCP API)

    private func loadInitialData() async {
        SMLog.api.info("Loading initial data via MCP API...")
        async let s: () = refreshSystem(force: true)
        async let c: () = refreshCargo(force: true)
        async let n: () = refreshNearby(force: true)
        async let sk: () = refreshSkills(force: true)
        async let m: () = refreshMissions()
        async let ch: () = refreshChat(channel: "system")
        async let cl: () = refreshCaptainsLog()
        async let st: () = refreshStorage(force: true)
        async let sh: () = refreshShip(force: true)
        async let os: () = refreshOwnedShips(force: true)
        _ = await (s, c, n, sk, m, ch, cl, st, sh, os)
        SMLog.api.info("Initial data loading complete")

        // Retry any data that failed during initial load (MCP session race)
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        var retried: [String] = []
        if shipDetail == nil { retried.append("get_ship"); await refreshShip(force: true) }
        if captainsLog == nil { retried.append("captains_log"); await refreshCaptainsLog() }
        if skills == nil { retried.append("get_skills"); await refreshSkills(force: true) }
        if system == nil { retried.append("get_system"); await refreshSystem(force: true) }
        if !retried.isEmpty {
            SMLog.api.info("Retried failed initial loads: \(retried.joined(separator: ", "))")
        }
    }

    // MARK: - WebSocket Push Event Processing

    private func handleMessage(_ message: WSRawMessage) {
        // Refresh skills on any real event (XP can change on any action)
        if message.type != "tick" {
            Task { await refreshSkills() }
        }

        switch message.type {
        case "state_update":
            handleStateUpdate(message.payloadData)
        case "chat_message":
            handleChatMessage(message.payloadData)
        case "combat_update":
            handleCombatUpdate(message.payloadData)
        case "mining_yield":
            handleMiningYield(message.payloadData)
        case "skill_level_up":
            handleSkillLevelUp(message.payloadData)
        case "poi_arrival":
            handlePoiEvent(message.payloadData, arrived: true)
        case "poi_departure":
            handlePoiEvent(message.payloadData, arrived: false)
        case "player_died":
            handlePlayerDied(message.payloadData)
        case "pirate_warning":
            handlePirateWarning(message.payloadData)
        case "pirate_combat":
            handlePirateCombat(message.payloadData)
        case "pirate_destroyed":
            handlePirateDestroyed(message.payloadData)
        case "ok":
            handleOkEvent(message.payloadData)
        case "action_result":
            handleActionResult(message.payloadData)
        case "action_error":
            handleActionError(message.payloadData)
        case "error":
            handleError(message.payloadData)
        case "gameplay_tip":
            handleGameplayTip(message.payloadData)
        case "tick":
            break
        default:
            let preview = String(data: message.payloadData.prefix(500), encoding: .utf8) ?? "(non-UTF8)"
            SMLog.websocket.warning("Unhandled WS event type: '\(message.type)' payload: \(preview)")
            appendEvent(category: .info, title: message.type, detail: preview, rawType: message.type)
        }
    }

    private func handleStateUpdate(_ data: Data) {
        guard let update = ResilientDecoder.decodeOrNil(StateUpdatePayload.self, from: data) else {
            SMLog.decode.error("Failed to decode state_update")
            return
        }

        currentTick = update.tick
        inCombat = update.inCombat ?? false
        travelProgress = update.travelProgress
        travelDestination = update.travelDestination

        // Build PlayerStatusResponse from push data
        playerStatus = PlayerStatusResponse(player: update.player, ship: update.ship)

        // Detect system change → trigger MCP refreshes
        let newSystem = update.player.currentSystem
        if previousSystem != nil && previousSystem != newSystem {
            SMLog.websocket.info("System changed: \(self.previousSystem ?? "?") -> \(newSystem)")
            appendEvent(category: .navigation, title: "Entered \(newSystem)", detail: nil, rawType: "system_change")
            Task {
                await refreshSystem()
                await refreshNearby()
            }
        }
        previousSystem = newSystem

        // Check docked status → trigger storage refresh
        if let docked = update.player.dockedAtBase, !docked.isEmpty {
            if storage == nil {
                Task { await refreshStorage() }
            }
        } else {
            storage = nil
        }

        // Retry ship detail if initial load failed
        if shipDetail == nil {
            Task { await refreshShip() }
        }

        lastError = nil
    }

    private func handleChatMessage(_ data: Data) {
        guard let payload = ResilientDecoder.decodeOrNil(ChatMessagePayload.self, from: data) else { return }

        let chatMsg = ChatMessage(
            id: payload.id ?? UUID().uuidString,
            channel: payload.channel ?? "system",
            senderId: payload.senderId ?? "",
            senderName: payload.sender ?? "Unknown",
            content: payload.content ?? "",
            timestamp: payload.timestamp ?? ISO8601DateFormatter().string(from: Date())
        )

        if var existing = chatMessages {
            var msgs = existing.messages
            msgs.append(chatMsg)
            chatMessages = ChatHistoryResponse(messages: msgs, hasMore: existing.hasMore)
        } else {
            chatMessages = ChatHistoryResponse(messages: [chatMsg], hasMore: false)
        }

        appendEvent(
            category: .info,
            title: "[\(chatMsg.channel)] \(chatMsg.senderName)",
            detail: formatChatContent(chatMsg.content),
            rawType: "chat_message"
        )
    }

    private func handleCombatUpdate(_ data: Data) {
        guard let payload = ResilientDecoder.decodeOrNil(CombatUpdatePayload.self, from: data) else { return }
        let detail = [
            payload.attacker.map { "Attacker: \($0)" },
            payload.target.map { "Target: \($0)" },
            payload.damage.map { "Damage: \($0)" },
            payload.damageType.map { "Type: \($0)" },
            payload.shieldHit == true ? "Shield hit" : nil,
            payload.hullHit == true ? "Hull hit" : nil,
            payload.destroyed == true ? "DESTROYED" : nil
        ].compactMap { $0 }.joined(separator: " | ")

        appendEvent(category: .combat, title: "Combat hit", detail: detail.isEmpty ? nil : detail, rawType: "combat_update")
        Task { await refreshNearby(force: true) }
    }

    private func handleMiningYield(_ data: Data) {
        guard let payload = ResilientDecoder.decodeOrNil(MiningYieldPayload.self, from: data) else { return }
        let resource = formatSnakeCase(payload.resourceId ?? "unknown")
        let qty = payload.quantity ?? 0
        appendEvent(category: .mining, title: "Mined \(qty)x \(resource)", detail: payload.remaining.map { "Remaining: \($0)" }, rawType: "mining_yield")
        Task { await refreshCargo() }
    }

    private func handleSkillLevelUp(_ data: Data) {
        guard let payload = ResilientDecoder.decodeOrNil(SkillLevelUpPayload.self, from: data) else { return }
        let skill = formatSnakeCase(payload.skillId ?? "unknown")
        let level = payload.newLevel ?? 0
        appendEvent(category: .skill, title: "\(skill) reached level \(level)", detail: payload.xpGained.map { "+\($0) XP" }, rawType: "skill_level_up")
    }

    private func handlePoiEvent(_ data: Data, arrived: Bool) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let who = json["username"] as? String ?? "Someone"
        let where_ = json["poi_name"] as? String ?? "unknown"
        let skipKeys: Set<String> = ["username", "poi_name", "poi_id", "poi_type", "type", "player_id", "clan_tag"]
        var details: [String] = []
        if let shipClass = json["ship_class"] as? String, !shipClass.trimmingCharacters(in: .whitespaces).isEmpty {
            details.append("Ship: \(formatSnakeCase(shipClass))")
        }
        if let clan = json["clan_tag"] as? String, !clan.trimmingCharacters(in: .whitespaces).isEmpty {
            details.append("Clan: \(clan)")
        }
        if let system = json["system_name"] as? String ?? json["system"] as? String, !system.trimmingCharacters(in: .whitespaces).isEmpty {
            details.append(system)
        }
        if let anonymous = json["anonymous"] as? Bool, anonymous {
            details.append("Anonymous")
        }
        if let inCombat = json["in_combat"] as? Bool, inCombat {
            details.append("In combat")
        }
        // Capture any remaining unknown fields
        let handledKeys = skipKeys.union(["ship_class", "system_name", "system", "anonymous", "in_combat"])
        for (key, value) in json where !handledKeys.contains(key) {
            if let str = value as? String, !str.trimmingCharacters(in: .whitespaces).isEmpty {
                details.append("\(formatSnakeCase(key)): \(str)")
            } else if let num = value as? NSNumber, !(value is Bool) {
                details.append("\(formatSnakeCase(key)): \(num)")
            }
        }
        appendEvent(
            category: .navigation,
            title: "\(who) \(arrived ? "arrived at" : "departed") \(where_)",
            detail: details.isEmpty ? nil : details.joined(separator: " | "),
            rawType: arrived ? "poi_arrival" : "poi_departure"
        )
        Task { await refreshNearby() }
    }

    private func handlePlayerDied(_ data: Data) {
        guard let payload = ResilientDecoder.decodeOrNil(PlayerDiedPayload.self, from: data) else { return }
        var details: [String] = []
        if let killer = payload.killer { details.append("Killed by: \(killer)") }
        if let respawn = payload.respawnBase { details.append("Respawn: \(respawn)") }
        if let cost = payload.cloneCost { details.append("Clone cost: \(cost)cr") }
        if let payout = payload.insurancePayout { details.append("Insurance: \(payout)cr") }
        if let ship = payload.newShipClass { details.append("New ship: \(formatSnakeCase(ship))") }
        appendEvent(
            category: .combat,
            title: "Ship destroyed!",
            detail: details.isEmpty ? nil : details.joined(separator: " | "),
            rawType: "player_died"
        )
    }

    private func handlePirateWarning(_ data: Data) {
        guard let payload = ResilientDecoder.decodeOrNil(PirateWarningPayload.self, from: data) else { return }
        let name = payload.pirateName ?? "Pirate"
        let tier = payload.pirateTier ?? "unknown"
        let boss = payload.isBoss == true ? " BOSS" : ""
        var details: [String] = ["\(tier.capitalized)\(boss) pirate"]
        if let message = payload.message { details.append(message) }
        appendEvent(
            category: .pirate,
            title: "\(name) attacking!",
            detail: details.joined(separator: " | "),
            rawType: "pirate_warning"
        )
        Task { await refreshNearby(force: true) }
    }

    private func handlePirateCombat(_ data: Data) {
        guard let payload = ResilientDecoder.decodeOrNil(PirateCombatPayload.self, from: data) else { return }
        let name = payload.pirateName ?? "Pirate"
        let dmg = payload.damage ?? 0
        let dmgType = payload.damageType ?? "unknown"
        let hull = payload.yourHull ?? 0
        let maxHull = payload.yourMaxHull ?? 0
        let shield = payload.yourShield ?? 0
        appendEvent(
            category: .pirate,
            title: "\(name) hit for \(dmg) \(dmgType)",
            detail: "Shield: \(shield) | Hull: \(hull)/\(maxHull)",
            rawType: "pirate_combat"
        )
        Task { await refreshNearby(force: true) }
    }

    private func handlePirateDestroyed(_ data: Data) {
        guard let payload = ResilientDecoder.decodeOrNil(PirateDestroyedPayload.self, from: data) else { return }
        let name = payload.pirateName ?? "Pirate"
        let tier = payload.pirateTier ?? ""
        let boss = payload.isBoss == true ? " BOSS" : ""
        var details: [String] = []
        if let xp = payload.combatXp { details.append("+\(xp) XP") }
        if let credits = payload.creditsEarned { details.append("+\(credits) credits") }
        appendEvent(
            category: .pirate,
            title: "\(name) destroyed!",
            detail: (["\(tier.capitalized)\(boss)"] + details).joined(separator: " | "),
            rawType: "pirate_destroyed"
        )
        Task {
            await refreshNearby(force: true)
            await refreshSkills(force: true)
        }
    }

    private func handleOkEvent(_ data: Data) {
        guard let payload = ResilientDecoder.decodeOrNil(OkActionPayload.self, from: data) else { return }

        switch payload.action {
        case "travel":
            let dest = payload.destination ?? "unknown"
            appendEvent(category: .navigation, title: "Traveling to \(dest)", detail: payload.message, rawType: "ok:travel")
        case "arrived":
            let dest = payload.destination ?? payload.system
            appendEvent(category: .navigation, title: "Arrived\(dest.map { " at \($0)" } ?? "")", detail: payload.message, rawType: "ok:arrived")
            Task {
                await refreshSystem()
                await refreshNearby()
            }
        case "dock":
            let base = payload.base ?? "station"
            appendEvent(category: .base, title: "Docked at \(base)", detail: payload.system.map { "System: \($0)" }, rawType: "ok:dock")
            Task {
                await refreshStorage()
                await refreshNearby()
            }
        case "undock":
            appendEvent(category: .base, title: "Undocked", detail: payload.message ?? payload.base, rawType: "ok:undock")
            storage = nil
            Task { await refreshNearby() }
        case "mine":
            appendEvent(category: .mining, title: "Mining", detail: payload.message, rawType: "ok:mine")
        case "jump":
            let dest = payload.destination ?? "unknown system"
            appendEvent(category: .navigation, title: "Jumping to \(dest)", detail: payload.message, rawType: "ok:jump")
            Task {
                await refreshSystem()
                await refreshNearby()
            }
        case "sell":
            appendEvent(category: .trade, title: "Sold items", detail: payload.message, rawType: "ok:sell")
            Task {
                await refreshCargo()
                await refreshStorage()
            }
        case "buy":
            appendEvent(category: .trade, title: "Bought items", detail: payload.message, rawType: "ok:buy")
            Task {
                await refreshCargo()
                await refreshOwnedShips()
            }
        case "craft":
            appendEvent(category: .trade, title: "Crafted item", detail: payload.message, rawType: "ok:craft")
            Task { await refreshCargo() }
        case "refuel":
            appendEvent(category: .base, title: "Refueled", detail: payload.message, rawType: "ok:refuel")
        case "repair":
            appendEvent(category: .base, title: "Repaired", detail: payload.message, rawType: "ok:repair")
        case "attack":
            let targetName = nearby?.pirates.first(where: { $0.pirateId == payload.target })?.name ?? payload.target ?? "enemy"
            appendEvent(category: .pirate, title: "Attacking \(targetName)", detail: payload.message, rawType: "ok:attack")
            Task { await refreshNearby(force: true) }
        case "flee":
            appendEvent(category: .pirate, title: "Fleeing!", detail: payload.message, rawType: "ok:flee")
        default:
            let detail = [payload.message, payload.destination, payload.base, payload.system, payload.target]
                .compactMap { $0 }.joined(separator: " | ")
            appendEvent(category: .system, title: formatSnakeCase(payload.action), detail: detail.isEmpty ? nil : detail, rawType: "ok:\(payload.action)")
        }
    }

    private func handleActionResult(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let command = json["command"] as? String ?? "unknown"
        let result = json["result"] as? [String: Any] ?? [:]
        if result.isEmpty {
            let preview = String(data: data.prefix(500), encoding: .utf8) ?? "(non-UTF8)"
            SMLog.websocket.warning("action_result: empty result dict, raw=\(preview)")
        }

        let category: GameEventCategory = switch command {
        case "analyze_market", "sell", "buy", "list_order", "cancel_order":
            .trade
        case "mine", "deep_core_mine":
            .mining
        case "scan":
            .scan
        case "attack", "flee":
            .pirate
        default:
            .system
        }

        let (title, detail) = actionResultDescription(command: command, result: result)
        appendEvent(category: category, title: title, detail: detail, rawType: "action_result:\(command)")
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func actionResultDescription(command: String, result: [String: Any]) -> (title: String, detail: String?) {
        var details: [String] = []

        switch command {
        case "analyze_market":
            if let analysis = result["analysis"] as? [String: Any] {
                for (itemKey, value) in analysis {
                    guard let item = value as? [String: Any] else { continue }
                    let name = item["item_name"] as? String ?? formatSnakeCase(itemKey)
                    details.append(name)
                    guard let stations = item["stations"] as? [Any],
                          let station = stations.first as? [String: Any] else { continue }
                    if let baseName = station["base_name"] as? String {
                        details.append("Station: \(baseName)")
                    }
                    let bestBuy = (station["best_player_buy"] as? NSNumber)?.intValue
                    let buyDepth = (station["player_buy_depth"] as? NSNumber)?.intValue
                    if let bb = bestBuy {
                        let depthStr = buyDepth.map { " (\($0) units)" } ?? ""
                        details.append("Best buy order: \(bb)cr\(depthStr)")
                    }
                    let bestSell = (station["best_player_sell"] as? NSNumber)?.intValue
                    let sellDepth = (station["player_sell_depth"] as? NSNumber)?.intValue
                    if let bs = bestSell {
                        let depthStr = sellDepth.map { " (\($0) units)" } ?? ""
                        details.append("Best sell order: \(bs)cr\(depthStr)")
                    }
                }
            }
            if let range = result["scanning_range"] as? String { details.append("Scan range: \(range)") }

        default:
            if let message = result["message"] as? String { details.append(formatChatContent(message)) }
            if let description = result["description"] as? String, description != result["message"] as? String {
                details.append(formatChatContent(description))
            }
            if let itemName = result["item_name"] as? String { details.append(itemName) }
            if let quantity = (result["quantity"] as? NSNumber)?.intValue { details.append("x\(quantity)") }
            if let amount = (result["amount"] as? NSNumber)?.intValue { details.append("x\(amount)") }
            if let credits = (result["credits"] as? NSNumber)?.intValue { details.append("\(credits) credits") }
            if let location = result["location"] as? String { details.append(location) }
            if let target = result["target"] as? String { details.append(target) }
            if let status = result["status"] as? String { details.append(status) }
        }

        // XP gained (common across all action_results)
        if let xpGained = result["xp_gained"] as? [String: Any], !xpGained.isEmpty {
            let xpParts = xpGained.compactMap { key, value -> String? in
                guard let xp = (value as? NSNumber)?.intValue else { return nil }
                return "+\(xp) \(formatSnakeCase(key)) XP"
            }
            if !xpParts.isEmpty { details.append(xpParts.joined(separator: ", ")) }
        }

        let title = formatSnakeCase(command)
        return (title, details.isEmpty ? nil : details.joined(separator: "\n"))
    }

    private func formatSnakeCase(_ text: String) -> String {
        text.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Format chat content: convert snake_case IDs to Title Case,
    /// clean up key=value bot command params, and format quoted snake_case.
    private func formatChatContent(_ content: String) -> String {
        var text = content
        // First: replace key=value pairs (e.g. "target_poi=haven_exchange" -> "Haven Exchange")
        // These are bot command params — just show the value, formatted
        if let kvRegex = try? NSRegularExpression(pattern: "\\b[a-z]+(?:_[a-z0-9]+)*=([a-z0-9]+(?:_[a-z0-9]+)*)\\b") {
            let matches = kvRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches.reversed() {
                guard let fullRange = Range(match.range, in: text),
                      let valueRange = Range(match.range(at: 1), in: text) else { continue }
                let value = String(text[valueRange])
                text.replaceSubrange(fullRange, with: formatSnakeCase(value))
            }
        }
        // Then: replace remaining snake_case tokens (2+ segments)
        if let snakeRegex = try? NSRegularExpression(pattern: "\\b([a-z]+(?:_[a-z0-9]+)+)\\b") {
            let matches = snakeRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches.reversed() {
                guard let range = Range(match.range, in: text) else { continue }
                let token = String(text[range])
                text.replaceSubrange(range, with: formatSnakeCase(token))
            }
        }
        // Also format 'quoted_snake_case' tokens
        if let quotedRegex = try? NSRegularExpression(pattern: "'([a-z]+(?:_[a-z0-9]+)+)'") {
            let matches = quotedRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches.reversed() {
                guard let fullRange = Range(match.range, in: text),
                      let innerRange = Range(match.range(at: 1), in: text) else { continue }
                let token = String(text[innerRange])
                text.replaceSubrange(fullRange, with: formatSnakeCase(token))
            }
        }
        return text
    }

    private func handleActionError(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let command = json["command"] as? String ?? "unknown"
        let message = json["message"] as? String ?? "Unknown error"
        let code = json["code"] as? String
        // Strip the "code: " prefix from message if present (e.g. "docked: Cannot jettison...")
        let cleanMessage: String
        if let code, message.hasPrefix("\(code): ") {
            cleanMessage = String(message.dropFirst(code.count + 2))
        } else {
            cleanMessage = message
        }
        appendEvent(
            category: .system,
            title: "\(formatSnakeCase(command)) failed",
            detail: cleanMessage,
            rawType: "action_error:\(command)"
        )
    }

    private func handleError(_ data: Data) {
        guard let payload = ResilientDecoder.decodeOrNil(ErrorPayload.self, from: data) else { return }
        let message = payload.message ?? "Unknown error"
        appendEvent(category: .system, title: "Error: \(message)", detail: payload.code, rawType: "error")
    }

    private func handleGameplayTip(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? String else { return }
        appendEvent(category: .info, title: "Tip: \(message)", detail: nil, rawType: "gameplay_tip")
    }

    // MARK: - Events

    private func appendEvent(category: GameEventCategory, title: String, detail: String?, rawType: String) {
        let event = GameEvent(timestamp: Date(), category: category, title: title, detail: detail, rawType: rawType)
        events.insert(event, at: 0)
        if events.count > Self.maxEvents {
            events.removeLast(events.count - Self.maxEvents)
        }
    }

    // MARK: - Throttling

    /// Returns true if the refresh should proceed, false if throttled.
    /// Always allows the call during initial load (when `initialLoadTask` is active).
    private func shouldRefresh(_ key: String) -> Bool {
        let interval = Self.throttleIntervals[key] ?? 5
        if let last = lastRefreshTime[key], Date().timeIntervalSince(last) < interval {
            SMLog.api.debug("Throttled \(key) (interval: \(interval)s)")
            return false
        }
        lastRefreshTime[key] = Date()
        return true
    }

    // MARK: - MCP API Data Refreshes

    private func refreshSystem(force: Bool = false) async {
        guard force || shouldRefresh("get_system") else { return }
        do {
            system = try await gameAPI.getSystem()
            SMLog.api.debug("System refreshed: \(self.system?.system.name ?? "?")")
            if let pois = system?.pois {
                await fetchPoiResources(for: pois)
            }
        } catch {
            SMLog.api.error("Failed to refresh system: \(error.localizedDescription)")
        }
    }

    private func fetchPoiResources(for pois: [PointOfInterest]) async {
        // Clear previous resources
        poiResources = [:]

        // Skip if POIs already have inline resources from get_system
        let needsFetch = pois.filter { $0.canHaveResources && ($0.resources == nil || $0.resources!.isEmpty) }
        let alreadyHave = pois.filter { $0.canHaveResources && $0.resources != nil && !$0.resources!.isEmpty }

        // Store inline resources
        for poi in alreadyHave {
            poiResources[poi.id] = poi.resources
        }

        guard !needsFetch.isEmpty else {
            SMLog.api.debug("All POI resources available inline, no get_poi calls needed")
            return
        }

        SMLog.api.debug("Fetching resources for \(needsFetch.count) POIs via get_poi")
        for poi in needsFetch {
            do {
                let detail = try await gameAPI.getPoi(id: poi.id)
                if let resources = detail.resources, !resources.isEmpty {
                    poiResources[poi.id] = resources
                }
            } catch {
                SMLog.api.debug("Failed to fetch POI \(poi.id) resources: \(error.localizedDescription)")
            }
        }
    }

    private func refreshCargo(force: Bool = false) async {
        guard force || shouldRefresh("get_cargo") else { return }
        do {
            cargo = try await gameAPI.getCargo()
        } catch {
            SMLog.api.error("Failed to refresh cargo: \(error.localizedDescription)")
        }
    }

    private func refreshNearby(force: Bool = false) async {
        guard force || shouldRefresh("get_nearby") else { return }
        do {
            nearby = try await gameAPI.getNearby()
            SMLog.api.debug("Nearby refreshed: \(self.nearby?.count ?? 0) players, \(self.nearby?.pirateCount ?? 0) pirates")
        } catch {
            SMLog.api.error("Failed to refresh nearby: \(error.localizedDescription)")
        }
    }

    private func refreshSkills(force: Bool = false) async {
        guard force || shouldRefresh("get_skills") else { return }
        do {
            skills = try await gameAPI.getSkills()
        } catch {
            SMLog.api.error("Failed to refresh skills: \(error.localizedDescription)")
        }
    }

    private func refreshMissions() async {
        do {
            missions = try await gameAPI.getActiveMissions()
        } catch {
            SMLog.api.error("Failed to refresh missions: \(error.localizedDescription)")
        }
    }

    func refreshChat(channel: String) async {
        do {
            chatMessages = try await gameAPI.getChatHistory(channel: channel)
            SMLog.api.debug("Chat refreshed: \(self.chatMessages?.messages.count ?? 0) messages")
        } catch {
            SMLog.api.error("Failed to refresh chat: \(error.localizedDescription)")
        }
    }

    func refreshCaptainsLog() async {
        do {
            captainsLog = try await gameAPI.getCaptainsLog()
        } catch {
            SMLog.api.error("Failed to refresh captain's log: \(error.localizedDescription)")
        }
    }

    private func refreshStorage(force: Bool = false) async {
        guard force || shouldRefresh("view_storage") else { return }
        do {
            storage = try await gameAPI.viewStorage()
        } catch {
            SMLog.api.debug("Storage refresh failed (may not be docked): \(error.localizedDescription)")
        }
    }

    private func refreshShip(force: Bool = false) async {
        guard force || shouldRefresh("get_ship") else { return }
        do {
            shipDetail = try await gameAPI.getShip()
        } catch {
            SMLog.api.error("Failed to refresh ship: \(error.localizedDescription)")
        }
    }

    private func refreshOwnedShips(force: Bool = false) async {
        guard force || shouldRefresh("list_ships") else { return }
        do {
            ownedShips = try await gameAPI.listShips()
        } catch {
            SMLog.api.error("Failed to refresh owned ships: \(error.localizedDescription)")
        }
    }
}
