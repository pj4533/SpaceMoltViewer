import SwiftUI

struct MissionInspectorView: View {
    let missionId: String
    let gameStateManager: GameStateManager

    private var mission: Mission? {
        gameStateManager.missions?.missions?.first { $0.id == missionId }
    }

    var body: some View {
        ScrollView {
            if let mission {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(mission.title)
                            .font(.title3.bold())
                        Spacer()
                        Text(mission.type.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }

                    Text(mission.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("OBJECTIVES")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ForEach(mission.objectives) { objective in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(objective.description)
                                    .font(.caption)
                                Spacer()
                                if objective.completed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                } else {
                                    Text("\(objective.current)/\(objective.required)")
                                        .font(.caption.monospacedDigit())
                                }
                            }
                            if !objective.completed {
                                ProgressView(value: objective.progress)
                                    .tint(.blue)
                            }
                        }
                    }

                    Divider()

                    Text("REWARDS")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let credits = mission.rewards.credits {
                        HStack(spacing: 4) {
                            Image(systemName: "creditcard")
                                .font(.caption)
                            Text("\(credits.formatted()) cr")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.green)
                        }
                    }

                    if let skillXp = mission.rewards.skillXp {
                        ForEach(Array(skillXp.keys.sorted()), id: \.self) { skill in
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                                Text("\(skill): +\(skillXp[skill] ?? 0) XP")
                                    .font(.caption)
                            }
                        }
                    }

                    if let ticks = mission.ticksRemaining {
                        Divider()
                        let minutes = ticks * 10 / 60
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text("\(minutes)m remaining")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(12)
            } else {
                Text("Mission not found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
    }
}
