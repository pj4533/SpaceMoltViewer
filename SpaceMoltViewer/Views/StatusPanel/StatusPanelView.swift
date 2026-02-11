import SwiftUI

struct StatusPanelView: View {
    let gameStateManager: GameStateManager
    var onFocusChange: (InspectorFocus) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    if let player = gameStateManager.playerStatus?.player {
                        PlayerIdentityCompact(player: player)

                        LocationCompact(
                            player: player,
                            system: gameStateManager.system,
                            onTap: {
                                onFocusChange(.systemDetail(player.currentSystem))
                            }
                        )
                    }

                    if let ship = gameStateManager.playerStatus?.ship {
                        ShipVitalsCompact(ship: ship, onTap: {
                            onFocusChange(.shipDetail)
                        })
                    }

                    if let nearby = gameStateManager.nearby {
                        NearbyCompact(nearby: nearby, onTap: {
                            onFocusChange(.nearbyDetail)
                        })
                    }

                    if let missions = gameStateManager.missions {
                        MissionsCompact(missions: missions, onTapMission: { id in
                            onFocusChange(.missionDetail(id))
                        })
                    }

                    if let cargo = gameStateManager.cargo {
                        CargoCompact(cargo: cargo, onTap: {
                            onFocusChange(.cargoDetail)
                        })
                    }

                    if let storage = gameStateManager.storage {
                        StorageCompact(storage: storage, onTap: {
                            onFocusChange(.storageDetail)
                        })
                    }

                    // Skills summary tap target
                    if let skills = gameStateManager.skills {
                        Button {
                            onFocusChange(.skillsOverview)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("SKILLS")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(skills.playerSkillCount) trained")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                let totalLevels = skills.playerSkills.reduce(0) { $0 + $1.level }
                                Text("Total levels: \(totalLevels)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }

            Divider()

            ConnectionStatusCompact(
                connectionState: gameStateManager.isConnected ? .connected : .disconnected,
                isLive: gameStateManager.isConnected
            )
        }
    }
}
