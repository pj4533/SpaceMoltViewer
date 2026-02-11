import SwiftUI

struct GaugeRow: View {
    let label: String
    let value: Int
    let max: Int
    let percent: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)/\(max)")
                    .font(.caption.monospacedDigit())
            }
            ProgressView(value: percent)
                .tint(color)
        }
    }
}
