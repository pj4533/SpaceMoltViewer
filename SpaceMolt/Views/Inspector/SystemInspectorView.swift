import SwiftUI

struct SystemInspectorView: View {
    let systemId: String
    let mapViewModel: MapViewModel
    let pollingManager: PollingManager

    private var mapSystem: MapSystem? {
        mapViewModel.systems.first { $0.id == systemId }
    }

    private var isCurrent: Bool {
        mapViewModel.currentSystem == systemId
    }

    private var isVisited: Bool {
        mapViewModel.discoveredSystems.contains(systemId)
    }

    /// If this is the current system, show detailed system info from polling
    private var currentSystemDetail: SystemResponse? {
        guard isCurrent else { return nil }
        return pollingManager.system
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
                            .fill(empireColor(empire))
                            .frame(width: 8, height: 8)
                        Text(empire.capitalized)
                            .font(.caption)
                        if mapSystem?.isHome == true {
                            Text("CAPITAL")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(empireColor(empire), in: Capsule())
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
                        .foregroundStyle(detail.securityStatus.contains("Lawless") || detail.securityStatus.contains("no police") ? .red : .green)

                    if !detail.pois.isEmpty {
                        Text("POINTS OF INTEREST")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ForEach(detail.pois) { poi in
                            HStack(spacing: 6) {
                                Image(systemName: poi.poiIcon)
                                    .frame(width: 14)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(poi.name)
                                    .font(.caption)
                                Spacer()
                                Text(poi.type)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    private func empireColor(_ empire: String) -> Color {
        switch empire.lowercased() {
        case "solarian": return Color(red: 0.29, green: 0.56, blue: 0.85)
        case "voidborn": return Color(red: 0, green: 1, blue: 1)
        case "crimson": return Color(red: 0.86, green: 0.08, blue: 0.24)
        case "nebula": return Color(red: 1, green: 0.84, blue: 0)
        case "outerrim": return Color(red: 0.25, green: 0.41, blue: 0.88)
        default: return .gray
        }
    }
}
