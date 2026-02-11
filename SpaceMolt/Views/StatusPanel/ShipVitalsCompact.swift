import SwiftUI

struct ShipVitalsCompact: View {
    let ship: ShipOverview
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(ship.name)
                        .font(.caption.bold())
                    Spacer()
                    Text(ship.classId.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    GaugeRow(label: "Hull", value: ship.hull, max: ship.maxHull, percent: ship.hullPercent, color: .green)
                    GaugeRow(label: "Shield", value: ship.shield, max: ship.maxShield, percent: ship.shieldPercent, color: .blue)
                    GaugeRow(label: "Fuel", value: ship.fuel, max: ship.maxFuel, percent: ship.fuelPercent, color: .orange)
                    GaugeRow(label: "Cargo", value: ship.cargoUsed, max: ship.cargoCapacity, percent: ship.cargoPercent, color: .purple)
                }

                HStack(spacing: 12) {
                    StatLabel(label: "Armor", value: "\(ship.armor)")
                    StatLabel(label: "Speed", value: String(format: "%.1f", ship.speed))
                    StatLabel(label: "CPU", value: "\(ship.cpuUsed)/\(ship.cpuMax)")
                    StatLabel(label: "Power", value: "\(ship.powerUsed)/\(ship.powerMax)")
                }
                .frame(maxWidth: .infinity)
            }
            .padding(10)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
