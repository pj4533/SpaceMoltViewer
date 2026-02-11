import Foundation
import Observation

@Observable
class SkillsViewModel {
    let pollingManager: PollingManager

    init(pollingManager: PollingManager) {
        self.pollingManager = pollingManager
    }

    var skills: SkillsResponse? { pollingManager.skills }

    var trainedSkills: [PlayerSkill] {
        skills?.playerSkills.sorted { $0.level > $1.level } ?? []
    }

    var totalSkillLevels: Int {
        trainedSkills.reduce(0) { $0 + $1.level }
    }
}
