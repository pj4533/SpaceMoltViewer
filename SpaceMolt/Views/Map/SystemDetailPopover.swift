import SwiftUI

struct SystemDetailPopover: View {
    let system: MapSystem
    let isCurrent: Bool
    let isVisited: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(system.name)
                    .font(.headline)
                if isCurrent {
                    Text("CURRENT")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green, in: Capsule())
                }
            }

            Text(system.id)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let empire = system.empire {
                Text("Empire: \(empire.capitalized)")
                    .font(.caption)
            }

            if let connections = system.connections {
                Text("Connections: \(connections.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(isVisited ? "Visited" : "Unexplored")
                .font(.caption)
                .foregroundStyle(isVisited ? .green : .orange)

            HStack {
                Text("X: \(String(format: "%.0f", system.x))")
                Text("Y: \(String(format: "%.0f", system.y))")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 200, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
