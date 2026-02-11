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
                        Text("\(nearby.count) players, \(nearby.pirateCount) pirates")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                                            Text(shipClass.replacingOccurrences(of: "_", with: " ").capitalized)
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
                            Text("PIRATES")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            ForEach(nearby.pirates) { pirate in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                        .font(.caption)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(pirate.name)
                                            .font(.caption)
                                        Text(pirate.shipClass.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("Hull: \(pirate.hullPercent)%")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
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
