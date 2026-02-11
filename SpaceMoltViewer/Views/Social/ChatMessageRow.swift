import SwiftUI

struct ChatMessageRow: View {
    let message: ChatMessage

    var body: some View {
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
