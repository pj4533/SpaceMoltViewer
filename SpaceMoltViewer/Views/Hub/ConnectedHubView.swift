import SwiftUI

struct ConnectedHubView: View {
    @Bindable var appViewModel: AppViewModel
    let gameStateManager: GameStateManager
    @Bindable var mapViewModel: MapViewModel

    @State private var bottomBarTab: BottomBarTab = .events

    var body: some View {
        VSplitView {
            HSplitView {
                // Left Panel: Status Strip
                StatusPanelView(
                    gameStateManager: gameStateManager,
                    onFocusChange: { appViewModel.inspectorFocus = $0 }
                )
                .frame(minWidth: 220, idealWidth: 240, maxWidth: 300)

                // Center Pane: Galaxy Map
                GalaxyMapView(viewModel: mapViewModel)
                    .frame(minWidth: 300)

                // Right Panel: Inspector
                InspectorPanelView(
                    focus: appViewModel.inspectorFocus,
                    gameStateManager: gameStateManager,
                    mapViewModel: mapViewModel,
                    onDismiss: { appViewModel.inspectorFocus = .none }
                )
                .frame(minWidth: 250, idealWidth: 280, maxWidth: 350)
            }

            // Bottom Bar: Events / Chat / Captain's Log
            ActivityBarView(
                gameStateManager: gameStateManager,
                selectedTab: $bottomBarTab
            )
            .frame(minHeight: 100, idealHeight: 150, maxHeight: 300)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 8) {
                    ConnectionIndicator(state: appViewModel.sessionManager.connectionState)
                    if gameStateManager.isConnected {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            Text("Live")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    if let error = gameStateManager.lastError {
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
    case events = "Events"
    case chat = "Chat"
    case log = "Captain's Log"

    var icon: String {
        switch self {
        case .events: return "bolt.fill"
        case .chat: return "bubble.left.and.bubble.right"
        case .log: return "book"
        }
    }
}
