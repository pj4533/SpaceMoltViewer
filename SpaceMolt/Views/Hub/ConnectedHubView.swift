import SwiftUI

struct ConnectedHubView: View {
    @Bindable var appViewModel: AppViewModel
    let pollingManager: PollingManager
    @Bindable var mapViewModel: MapViewModel

    @State private var bottomBarTab: BottomBarTab = .chat

    var body: some View {
        VSplitView {
            HSplitView {
                // Left Panel: Status Strip
                StatusPanelView(
                    pollingManager: pollingManager,
                    onFocusChange: { appViewModel.inspectorFocus = $0 }
                )
                .frame(minWidth: 220, idealWidth: 240, maxWidth: 300)

                // Center Pane: Galaxy Map
                GalaxyMapView(viewModel: mapViewModel)
                    .frame(minWidth: 300)

                // Right Panel: Inspector
                InspectorPanelView(
                    focus: appViewModel.inspectorFocus,
                    pollingManager: pollingManager,
                    mapViewModel: mapViewModel,
                    onDismiss: { appViewModel.inspectorFocus = .none }
                )
                .frame(minWidth: 250, idealWidth: 280, maxWidth: 350)
            }

            // Bottom Bar: Chat / Log / Alerts
            ActivityBarView(
                pollingManager: pollingManager,
                selectedTab: $bottomBarTab
            )
            .frame(minHeight: 100, idealHeight: 150, maxHeight: 300)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 8) {
                    ConnectionIndicator(state: appViewModel.sessionManager.connectionState)
                    if appViewModel.pollingManager?.isPolling == true {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Polling")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let error = appViewModel.pollingManager?.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

enum BottomBarTab: String, CaseIterable {
    case chat = "Chat"
    case log = "Captain's Log"
    case alerts = "Alerts"

    var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right"
        case .log: return "book"
        case .alerts: return "bell"
        }
    }
}
