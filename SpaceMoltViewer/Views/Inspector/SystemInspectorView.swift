import SwiftUI

struct SystemInspectorView: View {
    let systemId: String
    let mapViewModel: MapViewModel
    let gameStateManager: GameStateManager

    private var mapSystem: MapSystem? {
        mapViewModel.systems.first { $0.id == systemId }
    }

    private var isCurrent: Bool {
        mapViewModel.currentSystem == systemId
    }

    private var isVisited: Bool {
        mapViewModel.discoveredSystems.contains(systemId)
    }

    /// If this is the current system, show detailed system info
    private var currentSystemDetail: SystemResponse? {
        guard isCurrent else { return nil }
        return gameStateManager.system
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Text(mapSystem?.name ?? systemId)
                        .font(.title3.bold())
                    Spacer()
                    if isCurrent {
                        Text("CURRENT")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green, in: Capsule())
                    }
                }

                Text(systemId)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let empire = mapSystem?.empire {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(EmpireTheme.color(for: empire))
                            .frame(width: 8, height: 8)
                        Text(empire.capitalized)
                            .font(.caption)
                        if mapSystem?.isHome == true {
                            Text("CAPITAL")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(EmpireTheme.color(for: empire), in: Capsule())
                        }
                    }
                }

                if mapSystem?.isStronghold == true {
                    Text("PIRATE STRONGHOLD")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 1, green: 0.2, blue: 0.2), in: Capsule())
                }

                Text(isVisited ? "Visited" : "Unexplored")
                    .font(.caption)
                    .foregroundStyle(isVisited ? .green : .orange)

                if let sys = mapSystem {
                    HStack {
                        Text("X: \(String(format: "%.0f", sys.x))")
                        Text("Y: \(String(format: "%.0f", sys.y))")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                if let connections = mapSystem?.connections, !connections.isEmpty {
                    Divider()
                    Text("CONNECTIONS")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(connections.count) connected systems")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // If this is the current system, show detailed info
                if let detail = currentSystemDetail {
                    Divider()

                    Text(detail.securityStatus)
                        .font(.caption)
                        .foregroundStyle(detail.securityStatus.isLawless ? .red : .green)

                    if !detail.pois.isEmpty {
                        Text("POINTS OF INTEREST")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        PoiListView(pois: detail.pois, poiResources: gameStateManager.poiResources)
                    }
                }
            }
            .padding(12)
        }
    }

}
