import Foundation
import OSLog
import Observation

@Observable
class AppViewModel {
    let sessionManager = SessionManager()
    var gameAPI: GameAPI?
    var pollingManager: PollingManager?
    var settingsViewModel: SettingsViewModel?
    var mapViewModel: MapViewModel?
    var inspectorFocus: InspectorFocus = .none

    init() {
        SMLog.general.info("AppViewModel initialized")
        settingsViewModel = SettingsViewModel(sessionManager: sessionManager)
    }

    func onConnect() {
        SMLog.general.info("onConnect: creating GameAPI and PollingManager")
        let api = GameAPI(sessionManager: sessionManager)
        gameAPI = api
        let polling = PollingManager(gameAPI: api)
        pollingManager = polling
        mapViewModel = MapViewModel(pollingManager: polling, appViewModel: self)
        polling.startPolling()
        SMLog.general.info("onConnect: polling started")
    }

    func onDisconnect() {
        SMLog.general.info("onDisconnect: stopping polling and clearing state")
        pollingManager?.stopPolling()
        pollingManager = nil
        gameAPI = nil
        mapViewModel = nil
        inspectorFocus = .none
        sessionManager.disconnect()
        SMLog.general.info("onDisconnect: complete")
    }

    func autoConnectIfNeeded() async {
        guard !sessionManager.isConnected else {
            SMLog.general.debug("autoConnect: already connected, skipping")
            return
        }
        if let creds = KeychainService.load(), !creds.username.isEmpty {
            SMLog.general.info("autoConnect: found saved credentials for \(creds.username), attempting connection")
            await sessionManager.connect(username: creds.username, password: creds.password)
            if sessionManager.isConnected {
                SMLog.general.info("autoConnect: connection successful, starting polling")
                onConnect()
            } else {
                SMLog.general.warning("autoConnect: connection failed")
            }
        } else {
            SMLog.general.info("autoConnect: no saved credentials found")
        }
    }
}
