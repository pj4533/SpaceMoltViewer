import SwiftUI

struct ConnectionStatusCompact: View {
    let connectionState: ConnectionState
    let isLive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)
            Text(connectionState.statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if isLive {
                Spacer()
                Text("Live")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var indicatorColor: Color {
        switch connectionState {
        case .connected: return .green
        case .connecting, .reconnecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}
