import Foundation
import OSLog
import Observation

@Observable
class SocialViewModel {
    let pollingManager: PollingManager
    var selectedChannel: String = "system"

    init(pollingManager: PollingManager) {
        self.pollingManager = pollingManager
    }

    var messages: [ChatMessage] { pollingManager.chatMessages?.messages ?? [] }

    static let channels = ["system", "local", "faction"]

    func refreshChat() async {
        SMLog.ui.debug("Refreshing chat for channel: \(self.selectedChannel)")
        do {
            let response = try await pollingManager.gameAPI.getChatHistory(
                channel: selectedChannel
            )
            pollingManager.chatMessages = response
            SMLog.ui.debug("Chat refreshed: \(response.messages.count) messages")
        } catch {
            SMLog.ui.error("Failed to refresh chat: \(error.localizedDescription)")
        }
    }
}
