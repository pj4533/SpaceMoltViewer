import SwiftUI

struct ConnectionIndicator: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.color)
                .frame(width: 8, height: 8)
            Text(state.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

}
