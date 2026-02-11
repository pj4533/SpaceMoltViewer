import SwiftUI

struct ShipStatsView: View {
    let detail: ShipDetailResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(detail.shipClass.name)
                        .font(.title2.bold())
                    Text(detail.shipClass.shipCategory)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Value: \(detail.shipClass.price.formatted()) cr")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !detail.shipClass.description.isEmpty {
                Text(detail.shipClass.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 10) {
                StatBox(label: "Hull", value: "\(detail.ship.hull)/\(detail.ship.maxHull)")
                StatBox(label: "Shield", value: "\(detail.ship.shield)/\(detail.ship.maxShield)")
                StatBox(label: "Armor", value: "\(detail.ship.armor)")
                StatBox(label: "Fuel", value: "\(detail.ship.fuel)/\(detail.ship.maxFuel)")
                StatBox(label: "Speed", value: String(format: "%.1f", detail.ship.speed))
                StatBox(label: "Cargo", value: "\(detail.cargoUsed)/\(detail.cargoMax)")
            }

            Divider()

            if let cpuUsed = detail.ship.cpuUsed, let cpuCap = detail.ship.cpuCapacity,
               let powerUsed = detail.ship.powerUsed, let powerCap = detail.ship.powerCapacity {
                HStack(spacing: 20) {
                    ResourceBar(
                        label: "CPU",
                        used: cpuUsed,
                        max: cpuCap,
                        color: .cyan
                    )
                    ResourceBar(
                        label: "Power",
                        used: powerUsed,
                        max: powerCap,
                        color: .yellow
                    )
                }
            }

            HStack(spacing: 16) {
                SlotInfo(label: "Weapon", count: detail.shipClass.weaponSlots)
                SlotInfo(label: "Defense", count: detail.shipClass.defenseSlots)
                SlotInfo(label: "Utility", count: detail.shipClass.utilitySlots)
            }
            .font(.caption)
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct StatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.monospacedDigit().bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ResourceBar: View {
    let label: String
    let used: Int
    let max: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.bold())
                Spacer()
                Text("\(used)/\(max)")
                    .font(.caption.monospacedDigit())
            }
            ProgressView(value: max > 0 ? Double(used) / Double(max) : 0)
                .tint(color)
        }
    }
}

private struct SlotInfo: View {
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.secondary)
            Text("\(count)")
                .bold()
        }
    }
}
