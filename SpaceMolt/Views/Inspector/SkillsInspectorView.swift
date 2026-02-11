import SwiftUI

struct SkillsInspectorView: View {
    let pollingManager: PollingManager

    private var skills: [PlayerSkill] {
        pollingManager.skills?.playerSkills.sorted { $0.level > $1.level } ?? []
    }

    private var totalLevels: Int {
        skills.reduce(0) { $0 + $1.level }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Skills")
                        .font(.title3.bold())
                    Spacer()
                    Text("Total: \(totalLevels) levels")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if skills.isEmpty {
                    Text("No skills trained yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(skills) { skill in
                        SkillRowView(skill: skill)
                    }
                }
            }
            .padding(12)
        }
    }
}
