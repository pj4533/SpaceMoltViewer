import SwiftUI

struct MissionRowView: View {
    let mission: Mission

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(mission.title)
                    .font(.subheadline.bold())
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

            HStack {
                if let credits = mission.rewards.credits {
                    Text("Reward: \(credits.formatted()) cr")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                Spacer()
                if let ticks = mission.ticksRemaining {
                    let minutes = ticks * 10 / 60
                    Text("\(minutes)m remaining")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
