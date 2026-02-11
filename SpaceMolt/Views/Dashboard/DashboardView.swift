import SwiftUI

struct DashboardView: View {
    let viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let player = viewModel.player, let ship = viewModel.ship {
                    PlayerHeaderView(player: player)
                    ShipSummaryCard(ship: ship, viewModel: viewModel)

                    HStack(alignment: .top, spacing: 16) {
                        if let system = viewModel.system {
                            SystemInfoCard(system: system)
                        }
                        if let nearby = viewModel.nearby {
                            NearbyView(nearby: nearby)
                        }
                    }

                    if let cargo = viewModel.cargo {
                        CargoListView(cargo: cargo)
                    }
                } else {
                    EmptyStateView(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Waiting for Data",
                        message: "Connecting to game server..."
                    )
                }

                if let error = viewModel.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}
