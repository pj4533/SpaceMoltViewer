import SwiftUI

struct ChatMessageRow: View {
    let message: ChatMessage

    var body: some View {
        if message.isSystemBroadcast {
            systemBroadcastRow
        } else {
            standardRow
        }
    }

    private var systemBroadcastRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "megaphone.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text("SYSTEM BROADCAST")
                    .font(.caption.bold())
                    .foregroundStyle(.yellow)
                Spacer()
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(message.content)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.yellow.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.vertical, 2)
    }

    private var standardRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(message.senderName)
                .font(.caption.bold())
                .foregroundStyle(.blue)
                .frame(width: 80, alignment: .trailing)

            Text(message.content)
                .font(.caption)

            Spacer()

            Text(formattedTime)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var formattedTime: String {
        message.timestamp.isoTimeOnly
    }
}
