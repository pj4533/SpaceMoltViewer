import SwiftUI

struct SkillsView: View {
    let viewModel: SkillsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !viewModel.trainedSkills.isEmpty {
                    HStack {
                        Text("Trained Skills")
                            .font(.headline)
                        Spacer()
                        Text("Total Levels: \(viewModel.totalSkillLevels)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(viewModel.trainedSkills) { skill in
                        SkillRowView(skill: skill)
                    }
                } else {
                    EmptyStateView(
                        icon: "star.fill",
                        title: "No Skills Data",
                        message: "Waiting for skill information..."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Skills")
    }
}
