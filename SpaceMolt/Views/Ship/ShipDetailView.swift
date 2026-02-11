import SwiftUI

struct ShipDetailView: View {
    let viewModel: ShipViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let detail = viewModel.shipDetail {
                    ShipStatsView(detail: detail, viewModel: viewModel)
                    ModuleListView(modules: detail.modules)
                } else if let overview = viewModel.shipOverview {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(overview.name)
                            .font(.title2.bold())
                        Text("Loading detailed ship info...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                } else {
                    EmptyStateView(
                        icon: "airplane",
                        title: "No Ship Data",
                        message: "Waiting for ship information..."
                    )
                }

                if let owned = viewModel.ownedShips {
                    OwnedShipsView(ownedShips: owned)
                }
            }
            .padding()
        }
        .navigationTitle("Ship")
    }
}
