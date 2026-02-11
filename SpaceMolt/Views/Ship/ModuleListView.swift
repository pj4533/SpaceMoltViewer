import SwiftUI

struct ModuleListView: View {
    let modules: [ShipModule]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Installed Modules (\(modules.count))")
                .font(.headline)

            if modules.isEmpty {
                Text("No modules installed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(modules) { module in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(module.name)
                                    .font(.subheadline)
                                Text(module.qualityGrade)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 12) {
                                Text("CPU: \(module.cpuUsage)")
                                Text("Power: \(module.powerUsage)")
                                if let mp = module.miningPower {
                                    Text("Mining: \(mp)")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(module.wearStatus)
                            .font(.caption)
                            .foregroundStyle(module.wear > 0 ? .orange : .green)
                    }
                    .padding(.vertical, 4)
                    if module.id != modules.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
