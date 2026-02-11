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
        case "solarian": return Color(red: 0.29, green: 0.56, blue: 0.85)
        case "voidborn": return Color(red: 0, green: 1, blue: 1)
        case "crimson": return Color(red: 0.86, green: 0.08, blue: 0.24)
        case "nebula": return Color(red: 1, green: 0.84, blue: 0)
        case "outerrim": return Color(red: 0.25, green: 0.41, blue: 0.88)
        default: return .secondary
        }
    }
}
