import SwiftUI

struct ShipSummaryCard: View {
    let ship: ShipOverview
    let viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ship.name)
                    .font(.headline)
                Spacer()
                Text(ship.classId.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 10) {
                GaugeRow(
                    label: "Hull",
                    value: ship.hull,
                    max: ship.maxHull,
                    percent: viewModel.hullPercent,
                    color: .green
                )
                GaugeRow(
                    label: "Shield",
                    value: ship.shield,
                    max: ship.maxShield,
                    percent: viewModel.shieldPercent,
                    color: .blue
                )
                GaugeRow(
                    label: "Fuel",
                    value: ship.fuel,
                    max: ship.maxFuel,
                    percent: viewModel.fuelPercent,
                    color: .orange
                )
                GaugeRow(
                    label: "Cargo",
                    value: ship.cargoUsed,
                    max: ship.cargoCapacity,
                    percent: viewModel.cargoPercent,
                    color: .purple
                )
            }

            HStack(spacing: 16) {
                StatLabel(label: "Armor", value: "\(ship.armor)")
                StatLabel(label: "Speed", value: String(format: "%.1f", ship.speed))
                StatLabel(label: "CPU", value: "\(ship.cpuUsed)/\(ship.cpuMax)")
                StatLabel(label: "Power", value: "\(ship.powerUsed)/\(ship.powerMax)")
            }
            .font(.caption)
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct GaugeRow: View {
    let label: String
    let value: Int
    let max: Int
    let percent: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)/\(max)")
                    .font(.caption.monospacedDigit())
            }
            ProgressView(value: percent)
                .tint(color)
        }
    }
}

private struct StatLabel: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.monospacedDigit().bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
