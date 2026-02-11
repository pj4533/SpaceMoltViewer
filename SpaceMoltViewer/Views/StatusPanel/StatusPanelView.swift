import SwiftUI

struct StatusPanelView: View {
    let pollingManager: PollingManager
    var onFocusChange: (InspectorFocus) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    if let player = pollingManager.playerStatus?.player {
                        PlayerIdentityCompact(player: player)

                        LocationCompact(
                            player: player,
                            system: pollingManager.system,
                            onTap: {
                                onFocusChange(.systemDetail(player.currentSystem))
                            }
                        )
                    }

                    if let ship = pollingManager.playerStatus?.ship {
                        ShipVitalsCompact(ship: ship, onTap: {
                            onFocusChange(.shipDetail)
                        })
                    }

                    if let nearby = pollingManager.nearby {
                        NearbyCompact(nearby: nearby, onTap: {
                            onFocusChange(.nearbyDetail)
                        })
                    }

                    if let missions = pollingManager.missions {
                        MissionsCompact(missions: missions, onTapMission: { id in
                            onFocusChange(.missionDetail(id))
                        })
                    }

                    if let cargo = pollingManager.cargo {
                        CargoCompact(cargo: cargo, onTap: {
                            onFocusChange(.cargoDetail)
                        })
                    }

                    // Skills summary tap target
                    if let skills = pollingManager.skills {
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
                connectionState: pollingManager.gameAPI.sessionManager.connectionState,
                isPolling: pollingManager.isPolling
            )
        }
    }
}
