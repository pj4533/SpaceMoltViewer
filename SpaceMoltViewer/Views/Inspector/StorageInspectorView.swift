import SwiftUI

struct StorageInspectorView: View {
    let pollingManager: PollingManager

    private var storage: StorageResponse? { pollingManager.storage }

    var body: some View {
        ScrollView {
            if let storage {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Storage")
                            .font(.title3.bold())
                        Spacer()
                    }

                    Text(storage.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Divider()

                    HStack {
                        Text("Credits Stored")
                            .font(.caption)
                        Spacer()
                        Text("\(storage.credits)")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(.yellow)
                    }

                    Divider()

                    if storage.items.isEmpty {
                        Text("No items in storage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        Text("ITEMS")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ForEach(storage.items) { item in
                            HStack {
                                Text(item.name)
                                    .font(.caption)
                                Spacer()
                                Text("x\(item.quantity)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(12)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "building.2")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Dock at a station to view storage")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }
}
