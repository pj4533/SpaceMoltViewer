import SwiftUI

struct AlertsFeedView: View {
    let pollingManager: PollingManager

    var body: some View {
        VStack(spacing: 0) {
            if let error = pollingManager.lastError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                Divider()
            }

            Text("No alerts")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
