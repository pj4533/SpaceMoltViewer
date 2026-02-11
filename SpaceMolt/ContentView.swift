import SwiftUI

struct ContentView: View {
    @Bindable var appViewModel: AppViewModel
    @State private var selectedTab: SidebarTab? = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .status) {
                StatusBarView(
                    connectionState: appViewModel.sessionManager.connectionState,
                    lastError: appViewModel.pollingManager?.lastError,
                    isPolling: appViewModel.pollingManager?.isPolling ?? false
                )
            }
        }
        .task {
            await appViewModel.autoConnectIfNeeded()
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .dashboard:
            if let polling = appViewModel.pollingManager {
                DashboardView(viewModel: DashboardViewModel(pollingManager: polling))
            } else {
                notConnectedView
            }

        case .ship:
            if let polling = appViewModel.pollingManager {
                ShipDetailView(viewModel: ShipViewModel(pollingManager: polling))
            } else {
                notConnectedView
            }

        case .map:
            if let polling = appViewModel.pollingManager {
                GalaxyMapView(viewModel: MapViewModel(pollingManager: polling))
            } else {
                notConnectedView
            }

        case .skills:
            if let polling = appViewModel.pollingManager {
                SkillsView(viewModel: SkillsViewModel(pollingManager: polling))
            } else {
                notConnectedView
            }

        case .missions:
            if let polling = appViewModel.pollingManager {
                MissionsView(viewModel: MissionsViewModel(pollingManager: polling))
            } else {
                notConnectedView
            }

        case .social:
            if let polling = appViewModel.pollingManager {
                SocialView(viewModel: SocialViewModel(pollingManager: polling))
            } else {
                notConnectedView
            }

        case .log:
            if let polling = appViewModel.pollingManager {
                CaptainsLogView(viewModel: LogViewModel(pollingManager: polling))
            } else {
                notConnectedView
            }

        case .settings:
            if let settingsVM = appViewModel.settingsViewModel {
                SettingsView(
                    viewModel: settingsVM,
                    onConnect: { appViewModel.onConnect() },
                    onDisconnect: { appViewModel.onDisconnect() }
                )
            }

        case nil:
            Text("Select a section from the sidebar")
                .foregroundStyle(.secondary)
        }
    }

    private var notConnectedView: some View {
        EmptyStateView(
            icon: "wifi.slash",
            title: "Not Connected",
            message: "Go to Settings to connect to the game server."
        )
    }
}
