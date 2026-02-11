import SwiftUI

struct HubView: View {
    @Bindable var appViewModel: AppViewModel

    var body: some View {
        Group {
            if appViewModel.sessionManager.isConnected,
               let polling = appViewModel.pollingManager,
               let mapVM = appViewModel.mapViewModel {
                ConnectedHubView(
                    appViewModel: appViewModel,
                    pollingManager: polling,
                    mapViewModel: mapVM
                )
            } else {
                loginPromptView
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await appViewModel.autoConnectIfNeeded()
        }
    }

    private var loginPromptView: some View {
        VStack(spacing: 20) {
            if case .connecting = appViewModel.sessionManager.connectionState {
                ProgressView("Connecting...")
                    .font(.title3)
            } else {
                EmptyStateView(
                    icon: "wifi.slash",
                    title: "Not Connected",
                    message: "Open Settings (Cmd+,) to connect to the game server."
                )

                if case .error(let msg) = appViewModel.sessionManager.connectionState {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
