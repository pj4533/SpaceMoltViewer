import Foundation
import OSLog
import Observation

@Observable
class PollingManager {
    let gameAPI: GameAPI

    // High frequency (5s)
    var playerStatus: PlayerStatusResponse?
    var cargo: CargoResponse?

    // Medium frequency (30s)
    var system: SystemResponse?
    var nearby: NearbyResponse?
    var missions: MissionsResponse?
    var drones: DronesResponse?
    var chatMessages: ChatHistoryResponse?

    // Low frequency (60s)
    var shipDetail: ShipDetailResponse?
    var skills: SkillsResponse?
    var ownedShips: OwnedShipsResponse?
    var orders: OrdersResponse?

    // One-time
    var publicMap: [MapSystem]?
    var captainsLog: CaptainsLogResponse?

    var lastError: String?
    var isPolling = false

    private var highFrequencyTask: Task<Void, Never>?
    private var mediumFrequencyTask: Task<Void, Never>?
    private var lowFrequencyTask: Task<Void, Never>?

    init(gameAPI: GameAPI) {
        self.gameAPI = gameAPI
        SMLog.polling.debug("PollingManager initialized")
    }

    func startPolling() {
        SMLog.polling.info("Starting all polling tiers")
        stopPolling()
        isPolling = true
        loadOnce()

        highFrequencyTask = Task {
            SMLog.polling.info("High-frequency polling started (5s interval)")
            while !Task.isCancelled {
                await pollHighFrequency()
                try? await Task.sleep(for: .seconds(5))
            }
            SMLog.polling.info("High-frequency polling stopped")
        }

        mediumFrequencyTask = Task {
            SMLog.polling.info("Medium-frequency polling started (30s interval)")
            while !Task.isCancelled {
                await pollMediumFrequency()
                try? await Task.sleep(for: .seconds(30))
            }
            SMLog.polling.info("Medium-frequency polling stopped")
        }

        lowFrequencyTask = Task {
            SMLog.polling.info("Low-frequency polling started (60s interval)")
            while !Task.isCancelled {
                await pollLowFrequency()
                try? await Task.sleep(for: .seconds(60))
            }
            SMLog.polling.info("Low-frequency polling stopped")
        }
    }

    func stopPolling() {
        guard isPolling else { return }
        SMLog.polling.info("Stopping all polling tiers")
        highFrequencyTask?.cancel()
        mediumFrequencyTask?.cancel()
        lowFrequencyTask?.cancel()
        highFrequencyTask = nil
        mediumFrequencyTask = nil
        lowFrequencyTask = nil
        isPolling = false
    }

    func refreshAll() async {
        SMLog.polling.info("Manual refresh of all tiers")
        await pollHighFrequency()
        await pollMediumFrequency()
        await pollLowFrequency()
    }

    private func loadOnce() {
        SMLog.polling.info("Loading one-time data (public map, captain's log)")
        Task {
            do {
                publicMap = try await GameAPI.fetchPublicMap()
                SMLog.polling.info("Public map loaded: \(self.publicMap?.count ?? 0) systems")
            } catch {
                SMLog.polling.error("Failed to load public map: \(error.localizedDescription)")
            }
        }
        Task {
            do {
                captainsLog = try await gameAPI.getCaptainsLog()
                SMLog.polling.info("Captain's log loaded: \(self.captainsLog?.entries.count ?? 0) entries")
            } catch {
                SMLog.polling.error("Failed to load captain's log: \(error.localizedDescription)")
            }
        }
    }

    private func pollHighFrequency() async {
        SMLog.polling.debug("High-frequency poll tick")
        do {
            async let statusResult = gameAPI.getStatus()
            async let cargoResult = gameAPI.getCargo()
            playerStatus = try await statusResult
            cargo = try await cargoResult
            lastError = nil
            SMLog.polling.debug("High-freq: status OK (credits: \(self.playerStatus?.player.credits ?? 0)), cargo OK (\(self.cargo?.used ?? 0)/\(self.cargo?.capacity ?? 0))")
        } catch {
            lastError = error.localizedDescription
            SMLog.polling.error("High-freq poll failed: \(error.localizedDescription)")
        }
    }

    private func pollMediumFrequency() async {
        SMLog.polling.debug("Medium-frequency poll tick")
        do {
            system = try await gameAPI.getSystem()
            nearby = try await gameAPI.getNearby()
            missions = try await gameAPI.getActiveMissions()
            drones = try await gameAPI.getDrones()
            chatMessages = try await gameAPI.getChatHistory(channel: "system")
            SMLog.polling.debug("Medium-freq: system=\(self.system?.system.name ?? "?"), nearby=\(self.nearby?.count ?? 0) players + \(self.nearby?.pirateCount ?? 0) pirates, missions=\(self.missions?.totalCount ?? 0)")
        } catch {
            lastError = error.localizedDescription
            SMLog.polling.error("Medium-freq poll failed: \(error.localizedDescription)")
        }
    }

    private func pollLowFrequency() async {
        SMLog.polling.debug("Low-frequency poll tick")
        do {
            shipDetail = try await gameAPI.getShip()
            skills = try await gameAPI.getSkills()
            ownedShips = try await gameAPI.listShips()
            SMLog.polling.debug("Low-freq: ship modules=\(self.shipDetail?.modules.count ?? 0), skills=\(self.skills?.playerSkillCount ?? 0), owned ships=\(self.ownedShips?.count ?? 0)")
        } catch {
            SMLog.polling.error("Low-freq poll failed (ship/skills/ships): \(error.localizedDescription)")
            lastError = error.localizedDescription
        }
        do {
            orders = try await gameAPI.viewOrders()
            SMLog.polling.debug("Low-freq: orders=\(self.orders?.orders.count ?? 0)")
        } catch {
            SMLog.polling.debug("Low-freq: view_orders failed (may not be docked): \(error.localizedDescription)")
        }
    }
}
