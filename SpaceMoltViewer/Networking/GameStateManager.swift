import Foundation
import OSLog
import Observation

@Observable
class GameStateManager {
    let webSocketClient: WebSocketClient
    let gameAPI: GameAPI

    // Game state properties (same as old PollingManager for view compatibility)
    var playerStatus: PlayerStatusResponse?
    var cargo: CargoResponse?
    var system: SystemResponse?
    var nearby: NearbyResponse?
    var missions: MissionsResponse?
    var drones: DronesResponse?
    var chatMessages: ChatHistoryResponse?
    var storage: StorageResponse?
    var shipDetail: ShipDetailResponse?
    var skills: SkillsResponse?
    var ownedShips: OwnedShipsResponse?
    var orders: OrdersResponse?
    var publicMap: [MapSystem]?
    var captainsLog: CaptainsLogResponse?

    var lastError: String?
    var isConnected: Bool { _isConnected }

    // WebSocket-driven properties
    var events: [GameEvent] = []
    var currentTick: Int?
    var inCombat: Bool = false
    var travelProgress: Double?
    var travelDestination: String?

    // Private
    private var _isConnected = false
    private var messageTask: Task<Void, Never>?
    private var previousSystem: String?
    private static let maxEvents = 200

    init(webSocketClient: WebSocketClient, gameAPI: GameAPI) {
        self.webSocketClient = webSocketClient
        self.gameAPI = gameAPI
        SMLog.websocket.debug("GameStateManager initialized")
    }

    func start() {
        SMLog.websocket.info("GameStateManager starting")
        _isConnected = true

        // Load public map (HTTP, not MCP)
        Task {
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
                await MainActor.run {
                    self.handleMessage(message)
                }
            }
            SMLog.websocket.debug("Message processing loop ended")
        }

        // Load initial data via MCP API
        Task { await loadInitialData() }
    }

    func stop() {
        SMLog.websocket.info("GameStateManager stopping")
        messageTask?.cancel()
        messageTask = nil
        _isConnected = false
    }

    // MARK: - Initial Data Load (MCP API)

    private func loadInitialData() async {
        SMLog.api.info("Loading initial data via MCP API...")
        // Fire all initial queries — continue even if some fail
        await refreshSystem()
        await refreshCargo()
        await refreshNearby()
        await refreshMissions()
        await refreshDrones()
        await refreshChat(channel: "system")
        await refreshShip()
        await refreshSkills()
        await refreshCaptainsLog()
        await refreshOwnedShips()
        SMLog.api.info("Initial data loading complete")
    }

    // MARK: - WebSocket Push Event Processing

    private func handleMessage(_ message: WSRawMessage) {
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
        case "ok":
            handleOkEvent(message.payloadData)
        case "gameplay_tip":
            handleGameplayTip(message.payloadData)
        case "tick":
            break
        default:
            appendEvent(category: .info, title: message.type, detail: nil, rawType: message.type)
        }
    }

    private func handleStateUpdate(_ data: Data) {
        guard let update = try? JSONDecoder().decode(StateUpdatePayload.self, from: data) else {
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

        lastError = nil
    }

    private func handleChatMessage(_ data: Data) {
        guard let payload = try? JSONDecoder().decode(ChatMessagePayload.self, from: data) else { return }

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
            title: "[\(chatMsg.channel)] \(chatMsg.senderName): \(chatMsg.content)",
            detail: nil,
            rawType: "chat_message"
        )
    }

    private func handleCombatUpdate(_ data: Data) {
        guard let payload = try? JSONDecoder().decode(CombatUpdatePayload.self, from: data) else { return }
        let detail = [
            payload.attacker.map { "Attacker: \($0)" },
            payload.target.map { "Target: \($0)" },
            payload.damage.map { "Damage: \($0)" },
            payload.damageType.map { "Type: \($0)" },
            payload.destroyed == true ? "DESTROYED" : nil
        ].compactMap { $0 }.joined(separator: " | ")

        appendEvent(category: .combat, title: "Combat hit", detail: detail.isEmpty ? nil : detail, rawType: "combat_update")
    }

    private func handleMiningYield(_ data: Data) {
        guard let payload = try? JSONDecoder().decode(MiningYieldPayload.self, from: data) else { return }
        let resource = payload.resourceId ?? "unknown"
        let qty = payload.quantity ?? 0
        appendEvent(category: .mining, title: "Mined \(qty)x \(resource)", detail: payload.remaining.map { "Remaining: \($0)" }, rawType: "mining_yield")
        // Cargo changed — refresh via API
        Task { await refreshCargo() }
    }

    private func handleSkillLevelUp(_ data: Data) {
        guard let payload = try? JSONDecoder().decode(SkillLevelUpPayload.self, from: data) else { return }
        let skill = payload.skillId ?? "unknown"
        let level = payload.newLevel ?? 0
        appendEvent(category: .skill, title: "\(skill) reached level \(level)", detail: payload.xpGained.map { "+\($0) XP" }, rawType: "skill_level_up")
        Task { await refreshSkills() }
    }

    private func handlePoiEvent(_ data: Data, arrived: Bool) {
        guard let payload = try? JSONDecoder().decode(PoiEventPayload.self, from: data) else { return }
        let who = payload.username ?? "Someone"
        let where_ = payload.poiName ?? "unknown"
        appendEvent(
            category: .navigation,
            title: "\(who) \(arrived ? "arrived at" : "departed") \(where_)",
            detail: nil,
            rawType: arrived ? "poi_arrival" : "poi_departure"
        )
        Task { await refreshNearby() }
    }

    private func handlePlayerDied(_ data: Data) {
        guard let payload = try? JSONDecoder().decode(PlayerDiedPayload.self, from: data) else { return }
        appendEvent(
            category: .combat,
            title: "Ship destroyed",
            detail: payload.killer.map { "Killed by: \($0)" },
            rawType: "player_died"
        )
    }

    private func handleOkEvent(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let action = json["action"] as? String else { return }

        switch action {
        case "travel":
            let dest = json["destination"] as? String ?? "unknown"
            appendEvent(category: .navigation, title: "Traveling to \(dest)", detail: nil, rawType: "ok:travel")
        case "arrived":
            appendEvent(category: .navigation, title: "Arrived at destination", detail: nil, rawType: "ok:arrived")
            Task {
                await refreshSystem()
                await refreshNearby()
            }
        case "dock":
            let base = json["base"] as? String ?? "station"
            appendEvent(category: .base, title: "Docked at \(base)", detail: nil, rawType: "ok:dock")
            Task {
                await refreshStorage()
                await refreshNearby()
            }
        case "undock":
            appendEvent(category: .base, title: "Undocked", detail: nil, rawType: "ok:undock")
            storage = nil
            Task { await refreshNearby() }
        case "mine":
            appendEvent(category: .mining, title: "Mining", detail: nil, rawType: "ok:mine")
        case "jump":
            let dest = json["destination"] as? String ?? "unknown system"
            appendEvent(category: .navigation, title: "Jumping to \(dest)", detail: nil, rawType: "ok:jump")
            Task {
                await refreshSystem()
                await refreshNearby()
            }
        case "sell":
            appendEvent(category: .trade, title: "Sold items", detail: nil, rawType: "ok:sell")
            Task {
                await refreshCargo()
                await refreshStorage()
            }
        case "buy":
            appendEvent(category: .trade, title: "Bought items", detail: nil, rawType: "ok:buy")
            Task {
                await refreshCargo()
                await refreshOwnedShips()
            }
        case "craft":
            appendEvent(category: .trade, title: "Crafted item", detail: nil, rawType: "ok:craft")
            Task { await refreshCargo() }
        case "refuel":
            appendEvent(category: .base, title: "Refueled", detail: nil, rawType: "ok:refuel")
        case "repair":
            appendEvent(category: .base, title: "Repaired", detail: nil, rawType: "ok:repair")
        default:
            appendEvent(category: .system, title: action, detail: nil, rawType: "ok:\(action)")
        }
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

    // MARK: - MCP API Data Refreshes

    func refreshSystem() async {
        do {
            system = try await gameAPI.getSystem()
            SMLog.api.debug("System refreshed: \(self.system?.system.name ?? "?")")
        } catch {
            SMLog.api.error("Failed to refresh system: \(error.localizedDescription)")
        }
    }

    func refreshCargo() async {
        do {
            cargo = try await gameAPI.getCargo()
        } catch {
            SMLog.api.error("Failed to refresh cargo: \(error.localizedDescription)")
        }
    }

    func refreshNearby() async {
        do {
            nearby = try await gameAPI.getNearby()
            SMLog.api.debug("Nearby refreshed: \(self.nearby?.count ?? 0) players, \(self.nearby?.pirateCount ?? 0) pirates")
        } catch {
            SMLog.api.error("Failed to refresh nearby: \(error.localizedDescription)")
        }
    }

    func refreshSkills() async {
        do {
            skills = try await gameAPI.getSkills()
        } catch {
            SMLog.api.error("Failed to refresh skills: \(error.localizedDescription)")
        }
    }

    func refreshMissions() async {
        do {
            missions = try await gameAPI.getActiveMissions()
        } catch {
            SMLog.api.error("Failed to refresh missions: \(error.localizedDescription)")
        }
    }

    func refreshDrones() async {
        do {
            drones = try await gameAPI.getDrones()
        } catch {
            SMLog.api.error("Failed to refresh drones: \(error.localizedDescription)")
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

    func refreshStorage() async {
        do {
            storage = try await gameAPI.viewStorage()
        } catch {
            SMLog.api.debug("Storage refresh failed (may not be docked): \(error.localizedDescription)")
        }
    }

    func refreshShip() async {
        do {
            shipDetail = try await gameAPI.getShip()
        } catch {
            SMLog.api.error("Failed to refresh ship: \(error.localizedDescription)")
        }
    }

    func refreshOwnedShips() async {
        do {
            ownedShips = try await gameAPI.listShips()
        } catch {
            SMLog.api.error("Failed to refresh owned ships: \(error.localizedDescription)")
        }
    }
}
