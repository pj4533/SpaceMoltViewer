import SwiftUI

struct StatusBarView: View {
    let connectionState: ConnectionState
    let lastError: String?
    let isPolling: Bool

    var body: some View {
        HStack {
            ConnectionIndicator(state: connectionState)

            Spacer()

            if isPolling {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Polling")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.bar)
    }
}
