import SwiftUI

struct ConnectionStatusCompact: View {
    let connectionState: ConnectionState
    let isLive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connectionState.color)
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

}
