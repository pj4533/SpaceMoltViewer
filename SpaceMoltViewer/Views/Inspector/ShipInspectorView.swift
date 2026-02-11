import SwiftUI

struct ShipInspectorView: View {
    let gameStateManager: GameStateManager

    private var shipOverview: ShipOverview? { gameStateManager.playerStatus?.ship }
    private var shipDetail: ShipDetailResponse? { gameStateManager.shipDetail }
    private var ownedShips: OwnedShipsResponse? { gameStateManager.ownedShips }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if let overview = shipOverview {
                    // Ship name and class
                    HStack {
                        Text(overview.name)
                            .font(.title3.bold())
                        Spacer()
                    }
                    Text(overview.classId.displayFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Detailed class info if available
                    if let detail = shipDetail {
                        if !detail.shipClass.description.isEmpty {
                            Text(detail.shipClass.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("Value: \(detail.shipClass.price.formatted()) cr")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Vitals
                    Text("VITALS")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 4) {
                        GaugeRow(label: "Hull", value: overview.hull, max: overview.maxHull, percent: overview.hullPercent, color: .green)
                        GaugeRow(label: "Shield", value: overview.shield, max: overview.maxShield, percent: overview.shieldPercent, color: .blue)
                        GaugeRow(label: "Fuel", value: overview.fuel, max: overview.maxFuel, percent: overview.fuelPercent, color: .orange)
                        GaugeRow(label: "Cargo", value: overview.cargoUsed, max: overview.cargoCapacity, percent: overview.cargoPercent, color: .purple)
                    }

                    Divider()

                    // Stats grid
                    Text("STATS")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        StatLabel(label: "Armor", value: "\(overview.armor)")
                        StatLabel(label: "Speed", value: String(format: "%.1f", overview.speed))
                        StatLabel(label: "CPU", value: "\(overview.cpuUsed)/\(overview.cpuMax)")
                        StatLabel(label: "Power", value: "\(overview.powerUsed)/\(overview.powerMax)")
                    }

                    // Modules
                    if let detail = shipDetail, !detail.modules.isEmpty {
                        Divider()
                        ModuleListView(modules: detail.modules)
                    }

                    // Owned ships
                    if let owned = ownedShips, owned.count > 1 {
                        Divider()
                        Text("OTHER SHIPS")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ForEach(owned.ships.filter { !$0.isActive }) { ship in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ship.className)
                                        .font(.caption)
                                    Text(ship.location)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("Hull: \(ship.hull)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } else {
                    Text("No ship data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(12)
        }
    }
}
