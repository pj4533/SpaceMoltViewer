import Foundation
import OSLog
import Observation

@MainActor @Observable
class AppViewModel {
    let sessionManager = SessionManager()
    private(set) var gameStateManager: GameStateManager?
    private(set) var settingsViewModel: SettingsViewModel?
    private(set) var mapViewModel: MapViewModel?
    var inspectorFocus: InspectorFocus = .none

    init() {
        SMLog.general.info("AppViewModel initialized")
        settingsViewModel = SettingsViewModel(sessionManager: sessionManager)
    }

    func onConnect() {
        SMLog.general.info("onConnect: creating GameStateManager")
        guard let client = sessionManager.webSocketClient else {
            SMLog.general.error("onConnect: no WebSocket client available")
            return
        }
        let api = GameAPI(sessionManager: sessionManager)
        let gsm = GameStateManager(webSocketClient: client, gameAPI: api)
        gameStateManager = gsm
        let mvm = MapViewModel(gameStateManager: gsm)
        mvm.onFocusChange = { [weak self] focus in
            self?.inspectorFocus = focus
        }
        mapViewModel = mvm
        gsm.start()
        SMLog.general.info("onConnect: GameStateManager started")
    }

    func onDisconnect() async {
        SMLog.general.info("onDisconnect: stopping and clearing state")
        gameStateManager?.stop()
        gameStateManager = nil
        mapViewModel = nil
        inspectorFocus = .none
        await sessionManager.disconnect()
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
                SMLog.general.info("autoConnect: connection successful, starting game state manager")
                onConnect()
            } else {
                SMLog.general.warning("autoConnect: connection failed")
            }
        } else {
            SMLog.general.info("autoConnect: no saved credentials found")
        }
    }
}
