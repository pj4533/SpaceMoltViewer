import SwiftUI

struct PlayerHeaderView: View {
    let player: Player

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.username)
                        .font(.title2.bold())
                    if !player.clanTag.isEmpty {
                        Text("[\(player.clanTag)]")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(player.empire.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.purple)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard")
                    Text("\(player.credits.formatted()) cr")
                        .font(.title3.monospacedDigit())
                }
                Text(player.currentSystem)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if player.isCloaked {
                Image(systemName: "eye.slash")
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
