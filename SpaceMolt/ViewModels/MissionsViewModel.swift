import Foundation
import Observation

@Observable
class MissionsViewModel {
    let pollingManager: PollingManager

    init(pollingManager: PollingManager) {
        self.pollingManager = pollingManager
    }

    var missionsResponse: MissionsResponse? { pollingManager.missions }
    var missions: [Mission] { missionsResponse?.missions ?? [] }
    var activeMissionCount: Int { missionsResponse?.totalCount ?? 0 }
    var maxMissions: Int { missionsResponse?.maxMissions ?? 5 }
}
