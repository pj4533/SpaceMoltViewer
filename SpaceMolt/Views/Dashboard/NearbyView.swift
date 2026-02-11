import SwiftUI

struct NearbyView: View {
    let nearby: NearbyResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nearby")
                .font(.headline)

            if nearby.count == 0 && nearby.pirateCount == 0 {
                Text("Nobody here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(nearby.nearby) { player in
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(player.displayName)
                            .font(.subheadline)
                        if let shipClass = player.shipClass {
                            Text(shipClass.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            ForEach(nearby.pirates) { pirate in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    VStack(alignment: .leading) {
                        Text(pirate.name)
                            .font(.subheadline)
                        Text("Hull: \(pirate.hullPercent)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
