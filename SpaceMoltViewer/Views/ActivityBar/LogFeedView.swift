import SwiftUI

struct LogFeedView: View {
    let gameStateManager: GameStateManager

    private var entries: [LogEntry] {
        gameStateManager.captainsLog?.entries ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(entries.count) entries")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    Task { await gameStateManager.refreshCaptainsLog() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            if entries.isEmpty {
                Text("No log entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(entries) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text("#\(entry.index)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                                Text(entry.entry)
                                    .font(.caption)
                                    .lineLimit(2)
                                Spacer()
                                Text(formatDate(entry.createdAt))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        if let tIndex = dateString.firstIndex(of: "T") {
            let timeStr = dateString[dateString.index(after: tIndex)...]
            if let zIndex = timeStr.firstIndex(of: "Z") ?? timeStr.firstIndex(of: "+") {
                return String(timeStr[..<zIndex].prefix(5))
            }
            return String(timeStr.prefix(5))
        }
        return dateString
    }
}
