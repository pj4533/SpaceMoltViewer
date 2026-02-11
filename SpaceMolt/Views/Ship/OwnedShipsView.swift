import SwiftUI

struct OwnedShipsView: View {
    let ownedShips: OwnedShipsResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Owned Ships (\(ownedShips.count))")
                .font(.headline)

            ForEach(ownedShips.ships) { ship in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(ship.className)
                                .font(.subheadline)
                            if ship.isActive {
                                Text("ACTIVE")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green, in: Capsule())
                            }
                        }
                        Text(ship.location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Hull: \(ship.hull)")
                            .font(.caption.monospacedDigit())
                        Text("Fuel: \(ship.fuel)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                if ship.id != ownedShips.ships.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
