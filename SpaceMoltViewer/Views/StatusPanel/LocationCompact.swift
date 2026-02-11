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
                        Text(player.currentPoi.replacingOccurrences(of: "_", with: " ").capitalized)
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

    private func securityLabel(_ status: String) -> String {
        if status.contains("Lawless") || status.contains("no police") { return "LAWLESS" }
        return "SECURE"
    }

    private func securityColor(_ status: String) -> Color {
        if status.contains("Lawless") || status.contains("no police") { return .red }
        return .green
    }
}
