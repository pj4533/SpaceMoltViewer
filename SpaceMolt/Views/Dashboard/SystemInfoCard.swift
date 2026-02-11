import SwiftUI

struct SystemInfoCard: View {
    let system: SystemResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(system.system.name)
                    .font(.headline)
                Spacer()
                Text(system.system.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(system.securityStatus)
                .font(.subheadline)
                .foregroundStyle(securityColor)

            Divider()

            Text("Points of Interest")
                .font(.subheadline.bold())

            ForEach(system.pois) { poi in
                HStack(spacing: 6) {
                    Image(systemName: poi.poiIcon)
                        .frame(width: 16)
                        .foregroundStyle(.secondary)
                    Text(poi.name)
                        .font(.caption)
                    Spacer()
                    Text(poi.type)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !system.system.connections.isEmpty {
                Divider()
                Text("Connections: \(system.system.connections.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    private var securityColor: Color {
        if system.securityStatus.contains("Lawless") { return .red }
        if system.securityStatus.contains("no police") { return .red }
        return .green
    }
}
