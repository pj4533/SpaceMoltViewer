import SwiftUI

struct InspectorEmptyView: View {
    let gameStateManager: GameStateManager

    var body: some View {
        if let system = gameStateManager.system {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current System")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(system.system.name)
                        .font(.title3.bold())

                    Text(system.securityStatus)
                        .font(.caption)
                        .foregroundStyle(system.securityStatus.isLawless ? .red : .green)

                    if !system.pois.isEmpty {
                        Divider()
                        Text("POINTS OF INTEREST")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        PoiListView(pois: system.pois)
                    }

                    if !system.system.connections.isEmpty {
                        Divider()
                        Text("CONNECTIONS")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ForEach(system.system.connections) { conn in
                            HStack {
                                Text(conn.name)
                                    .font(.caption)
                                Spacer()
                                Text("\(conn.distance) ly")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(12)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "sidebar.right")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Select something to inspect")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
