import Foundation
import Observation

@Observable
class DashboardViewModel {
    let pollingManager: PollingManager

    init(pollingManager: PollingManager) {
        self.pollingManager = pollingManager
    }

    var player: Player? { pollingManager.playerStatus?.player }
    var ship: ShipOverview? { pollingManager.playerStatus?.ship }
    var cargo: CargoResponse? { pollingManager.cargo }
    var system: SystemResponse? { pollingManager.system }
    var nearby: NearbyResponse? { pollingManager.nearby }
    var lastError: String? { pollingManager.lastError }

    var isDockedAtBase: Bool {
        guard let docked = player?.dockedAtBase else { return false }
        return !docked.isEmpty
    }

    var fuelPercent: Double {
        guard let s = ship, s.maxFuel > 0 else { return 0 }
        return Double(s.fuel) / Double(s.maxFuel)
    }

    var hullPercent: Double {
        guard let s = ship, s.maxHull > 0 else { return 0 }
        return Double(s.hull) / Double(s.maxHull)
    }

    var shieldPercent: Double {
        guard let s = ship, s.maxShield > 0 else { return 0 }
        return Double(s.shield) / Double(s.maxShield)
    }

    var cargoPercent: Double {
        guard let s = ship, s.cargoCapacity > 0 else { return 0 }
        return Double(s.cargoUsed) / Double(s.cargoCapacity)
    }
}
