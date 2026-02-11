import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var onConnect: () -> Void
    var onDisconnect: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connection")
                        .font(.headline)

                    ConnectionIndicator(state: viewModel.sessionManager.connectionState)

                    TextField("Username", text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.sessionManager.isConnected)

                    SecureField("Password Hash", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.sessionManager.isConnected)

                    HStack {
                        if viewModel.sessionManager.isConnected {
                            Button("Disconnect") {
                                viewModel.disconnect()
                                onDisconnect()
                            }
                            .tint(.red)
                        } else {
                            Button("Connect") {
                                Task {
                                    await viewModel.connect()
                                    if viewModel.sessionManager.isConnected {
                                        onConnect()
                                    }
                                }
                            }
                            .disabled(viewModel.username.isEmpty || viewModel.password.isEmpty)
                        }

                        Spacer()

                        Button("Clear Credentials") {
                            viewModel.clearCredentials()
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

                if case .error(let msg) = viewModel.sessionManager.connectionState {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                    Text("SpaceMolt Viewer — passive read-only dashboard for monitoring Drift's gameplay.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("All data is read-only. No game-state mutations are possible.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
}
