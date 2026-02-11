import SwiftUI

struct LogEntryView: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("#\(entry.index)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.createdAt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(entry.entry)
                .font(.subheadline)
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
