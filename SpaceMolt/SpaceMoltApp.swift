import SwiftUI

@main
struct SpaceMoltApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            HubView(appViewModel: appViewModel)
                .frame(minWidth: 1100, minHeight: 700)
        }

        Settings {
            if let settingsVM = appViewModel.settingsViewModel {
                SettingsView(
                    viewModel: settingsVM,
                    onConnect: { appViewModel.onConnect() },
                    onDisconnect: { appViewModel.onDisconnect() }
                )
                .frame(width: 450, height: 350)
            }
        }
    }
}
