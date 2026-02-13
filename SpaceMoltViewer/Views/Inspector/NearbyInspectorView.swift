import SwiftUI

struct NearbyInspectorView: View {
    let gameStateManager: GameStateManager

    private var nearby: NearbyResponse? { gameStateManager.nearby }

    var body: some View {
        ScrollView {
            if let nearby {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Nearby")
                            .font(.title3.bold())
                        Spacer()
                        if nearby.pirateCount > 0 {
                            Text("⚠ \(nearby.pirateCount) pirate\(nearby.pirateCount == 1 ? "" : "s")")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        }
                        if nearby.count > 0 {
                            Text("\(nearby.count) player\(nearby.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if nearby.count == 0 && nearby.pirateCount == 0 {
                        Text("Nobody here")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        if !nearby.nearby.isEmpty {
                            Divider()
                            Text("PLAYERS")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            ForEach(nearby.nearby) { player in
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.blue)
                                        .font(.caption)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(player.displayName)
                                            .font(.caption)
                                        if let shipClass = player.shipClass {
                                            Text(shipClass.displayFormatted)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if player.inCombat == true {
                                        Text("COMBAT")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.red)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }

                        if !nearby.pirates.isEmpty {
                            Divider()
                            HStack {
                                Text("☠️ PIRATES")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.red)
                                Spacer()
                            }

                            ForEach(nearby.pirates) { pirate in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(pirate.isBoss ? "💀" : "☠️")
                                            .font(.caption)
                                        Text(pirate.name)
                                            .font(.caption.bold())
                                            .foregroundStyle(.red)
                                        if pirate.isBoss {
                                            Text("BOSS")
                                                .font(.system(size: 8, weight: .black))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(.red, in: Capsule())
                                        }
                                        Spacer()
                                        Text(pirate.tier.capitalized)
                                            .font(.caption2)
                                            .foregroundStyle(.red.opacity(0.7))
                                    }
                                    HStack(spacing: 2) {
                                        Text(pirate.status.capitalized)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    HStack(spacing: 8) {
                                        GaugeRow(
                                            label: "Hull",
                                            value: pirate.hull,
                                            max: pirate.maxHull,
                                            percent: pirate.maxHull > 0 ? Double(pirate.hull) / Double(pirate.maxHull) : 0,
                                            color: .red
                                        )
                                        GaugeRow(
                                            label: "Shield",
                                            value: pirate.shield,
                                            max: pirate.maxShield,
                                            percent: pirate.maxShield > 0 ? Double(pirate.shield) / Double(pirate.maxShield) : 0,
                                            color: .blue
                                        )
                                    }
                                }
                                .padding(6)
                                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                                .padding(.vertical, 1)
                            }
                        }
                    }
                }
                .padding(12)
            } else {
                Text("No nearby data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
    }
}
