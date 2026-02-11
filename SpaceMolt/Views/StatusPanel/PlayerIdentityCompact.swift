import SwiftUI

struct PlayerIdentityCompact: View {
    let player: Player

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(player.username)
                    .font(.headline)
                if !player.clanTag.isEmpty {
                    Text("[\(player.clanTag)]")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if player.isCloaked {
                    Image(systemName: "eye.slash")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            HStack {
                Text(player.empire.capitalized)
                    .font(.caption)
                    .foregroundStyle(empireColor)
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "creditcard")
                        .font(.caption2)
                    Text("\(player.credits.formatted()) cr")
                        .font(.caption.monospacedDigit())
                }
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private var empireColor: Color {
        switch player.empire.lowercased() {
        case "nebula": return .purple
        case "solar": return .yellow
        case "void": return .cyan
        case "terra": return .green
        default: return .secondary
        }
    }
}
