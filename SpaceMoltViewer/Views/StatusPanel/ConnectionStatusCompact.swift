import SwiftUI

struct ConnectionStatusCompact: View {
    let connectionState: ConnectionState
    let isPolling: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)
            Text(connectionState.statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if isPolling {
                Spacer()
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var indicatorColor: Color {
        switch connectionState {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}
