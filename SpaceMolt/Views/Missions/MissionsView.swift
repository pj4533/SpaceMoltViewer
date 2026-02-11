import SwiftUI

struct MissionsView: View {
    let viewModel: MissionsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("Active Missions")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.activeMissionCount)/\(viewModel.maxMissions)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if viewModel.missions.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "No Active Missions",
                        message: "Drift doesn't have any missions right now."
                    )
                } else {
                    ForEach(viewModel.missions) { mission in
                        MissionRowView(mission: mission)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Missions")
    }
}
