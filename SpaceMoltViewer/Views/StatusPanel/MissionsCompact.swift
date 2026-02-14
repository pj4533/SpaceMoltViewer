import SwiftUI

struct MissionsCompact: View {
    let missions: MissionsResponse
    var onTapMission: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("MISSIONS")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(missions.totalCount ?? 0)/\(missions.maxMissions ?? 0)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if missions.missions?.isEmpty ?? true {
                Text("No active missions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
            } else {
                ForEach(missions.missions ?? []) { mission in
                    Button {
                        onTapMission(mission.id)
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(missionProgress(mission) >= 1.0 ? .green : .blue)
                                .frame(width: 6, height: 6)
                            Text(mission.title)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(missionProgress(mission) * 100))%")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private func missionProgress(_ mission: Mission) -> Double {
        guard !mission.objectives.isEmpty else { return 0 }
        let total = mission.objectives.reduce(0.0) { $0 + $1.progress }
        return total / Double(mission.objectives.count)
    }
}
