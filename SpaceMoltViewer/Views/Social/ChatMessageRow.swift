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
        // Show just the time portion from ISO timestamp
        if let tIndex = message.timestamp.firstIndex(of: "T") {
            let timeStr = message.timestamp[message.timestamp.index(after: tIndex)...]
            if let zIndex = timeStr.firstIndex(of: "Z") ?? timeStr.firstIndex(of: "+") {
                return String(timeStr[..<zIndex].prefix(5))
            }
            return String(timeStr.prefix(5))
        }
        return message.timestamp
    }
}
