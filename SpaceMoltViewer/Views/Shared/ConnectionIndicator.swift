import SwiftUI

struct ConnectionIndicator: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 8, height: 8)
            Text(state.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var indicatorColor: Color {
        switch state {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}
