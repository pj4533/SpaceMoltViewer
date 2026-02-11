import Foundation
import Observation

@Observable
class SettingsViewModel {
    var username = ""
    var password = ""

    let sessionManager: SessionManager

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        loadCredentials()
    }

    func loadCredentials() {
        if let creds = KeychainService.load() {
            username = creds.username
            password = creds.password
        }
    }

    func connect() async {
        guard !username.isEmpty, !password.isEmpty else { return }

        try? KeychainService.save(
            credentials: .init(username: username, password: password)
        )

        await sessionManager.connect(username: username, password: password)
    }

    func disconnect() {
        sessionManager.disconnect()
    }

    func clearCredentials() {
        KeychainService.delete()
        username = ""
        password = ""
    }
}
