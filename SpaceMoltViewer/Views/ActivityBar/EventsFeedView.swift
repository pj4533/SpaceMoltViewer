import SwiftUI

struct EventsFeedView: View {
    let gameStateManager: GameStateManager

    private var events: [GameEvent] {
        gameStateManager.events
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(events.count) events")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let tick = gameStateManager.currentTick {
                    Spacer()
                    Text("Tick \(tick)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if gameStateManager.inCombat {
                    Text("COMBAT")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
                if let progress = gameStateManager.travelProgress {
                    Text("Traveling \(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            if events.isEmpty {
                Text("Waiting for events...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(events) { event in
                            EventRow(event: event)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

private struct EventRow: View {
    let event: GameEvent

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(Self.timeFormatter.string(from: event.timestamp))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)

            Text(event.category.emoji)
                .font(.caption2)
                .frame(width: 12)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.caption)
                    .foregroundStyle(event.category.color)
                    .lineLimit(1)

                if let detail = event.detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 1)
    }
}
