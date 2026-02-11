import Foundation
import Observation

@Observable
class ShipViewModel {
    let pollingManager: PollingManager

    init(pollingManager: PollingManager) {
        self.pollingManager = pollingManager
    }

    var shipDetail: ShipDetailResponse? { pollingManager.shipDetail }
    var ownedShips: OwnedShipsResponse? { pollingManager.ownedShips }
    var shipOverview: ShipOverview? { pollingManager.playerStatus?.ship }

    var modules: [ShipModule] { shipDetail?.modules ?? [] }
    var shipClass: ShipClass? { shipDetail?.shipClass }
    var cpuPercent: Double {
        guard let ship = shipDetail?.ship,
              let used = ship.cpuUsed, let cap = ship.cpuCapacity, cap > 0 else { return 0 }
        return Double(used) / Double(cap)
    }

    var powerPercent: Double {
        guard let ship = shipDetail?.ship,
              let used = ship.powerUsed, let cap = ship.powerCapacity, cap > 0 else { return 0 }
        return Double(used) / Double(cap)
    }
}
