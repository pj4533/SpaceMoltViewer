import SwiftUI

struct LocationCompact: View {
    let player: Player
    let system: SystemResponse?
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(system?.system.name ?? player.currentSystem)
                        .font(.subheadline.bold())
                    Spacer()
                    if let system {
                        Text(securityLabel(system.securityStatus))
                            .font(.caption2)
                            .foregroundStyle(securityColor(system.securityStatus))
                    }
                }

                HStack(spacing: 8) {
                    if let docked = player.dockedAtBase, !docked.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "building.2.fill")
                                .font(.caption2)
                            Text("Docked")
                                .font(.caption)
                        }
                        .foregroundStyle(.green)
                    }

                    if !player.currentPoi.isEmpty {
                        Text(poiDisplayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var poiDisplayName: String {
        // Look up friendly name from system POI list
        if let pois = system?.pois,
           let poi = pois.first(where: { $0.id == player.currentPoi }) {
            return poi.name
        }
        return player.currentPoi.displayFormatted
    }

    private func securityLabel(_ status: String) -> String {
        if status.isLawless { return "LAWLESS" }
        return "SECURE"
    }

    private func securityColor(_ status: String) -> Color {
        if status.isLawless { return .red }
        return .green
    }
}
