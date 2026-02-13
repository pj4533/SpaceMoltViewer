import SwiftUI

struct NearbyCompact: View {
    let nearby: NearbyResponse
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("NEARBY")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if nearby.pirateCount > 0 {
                        Text("⚠ \(nearby.pirateCount) pirate\(nearby.pirateCount == 1 ? "" : "s")")
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                    }
                    if nearby.count > 0 {
                        Text("\(nearby.count) player\(nearby.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if nearby.count == 0 && nearby.pirateCount == 0 {
                    Text("Nobody here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 2)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(nearby.nearby.prefix(3)) { player in
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                Text(player.displayName)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                        ForEach(nearby.pirates.prefix(2)) { pirate in
                            HStack(spacing: 4) {
                                Text(pirate.isBoss ? "💀" : "☠️")
                                    .font(.caption2)
                                Text(pirate.name)
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(pirate.tier.capitalized)")
                                    .font(.caption2)
                                    .foregroundStyle(.red.opacity(0.7))
                                Text("\(pirate.hullPercent)%")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                        }
                        if nearby.count > 3 || nearby.pirateCount > 2 {
                            Text("+\(max(0, nearby.count - 3) + max(0, nearby.pirateCount - 2)) more")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(10)
            .background(
                nearby.pirateCount > 0
                    ? AnyShapeStyle(.red.opacity(0.12))
                    : AnyShapeStyle(.quaternary.opacity(0.5)),
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
    }
}
