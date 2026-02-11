import Foundation
import OSLog
import Observation

@Observable
class LogViewModel {
    let pollingManager: PollingManager

    init(pollingManager: PollingManager) {
        self.pollingManager = pollingManager
    }

    var logEntries: [LogEntry] { pollingManager.captainsLog?.entries ?? [] }

    func refresh() async {
        SMLog.ui.debug("Refreshing captain's log")
        do {
            pollingManager.captainsLog = try await pollingManager.gameAPI.getCaptainsLog()
            SMLog.ui.debug("Captain's log refreshed: \(self.logEntries.count) entries")
        } catch {
            SMLog.ui.error("Failed to refresh captain's log: \(error.localizedDescription)")
        }
    }
}
