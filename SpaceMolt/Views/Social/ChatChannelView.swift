import SwiftUI

struct ChatChannelView: View {
    let messages: [ChatMessage]

    var body: some View {
        if messages.isEmpty {
            EmptyStateView(
                icon: "bubble.left.and.bubble.right",
                title: "No Messages",
                message: "No messages in this channel yet."
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(messages) { message in
                        ChatMessageRow(message: message)
                    }
                }
                .padding()
            }
        }
    }
}
