import SwiftUI

struct StorageCompact: View {
    let storage: StorageResponse
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("STORAGE")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(storage.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Text("Credits:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(storage.credits)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.yellow)
                }

                if storage.items.isEmpty {
                    Text("No items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(storage.items.prefix(3)) { item in
                        HStack {
                            Text(item.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text("x\(item.quantity)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    if storage.items.count > 3 {
                        Text("+\(storage.items.count - 3) more items")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
