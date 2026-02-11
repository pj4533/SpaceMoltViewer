import SwiftUI

struct ChatFeedView: View {
    let pollingManager: PollingManager
    @State private var selectedChannel: String = "system"

    private static let channels = ["system", "local", "faction"]

    private var messages: [ChatMessage] {
        pollingManager.chatMessages?.messages ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(Self.channels, id: \.self) { channel in
                    Button {
                        selectedChannel = channel
                        Task { await pollingManager.refreshChat(channel: channel) }
                    } label: {
                        Text(channel.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(selectedChannel == channel ? .white.opacity(0.15) : .clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            if messages.isEmpty {
                Text("No messages in this channel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(messages) { message in
                            ChatMessageRow(message: message)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
