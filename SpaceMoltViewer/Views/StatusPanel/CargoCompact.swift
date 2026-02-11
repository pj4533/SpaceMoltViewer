import SwiftUI

struct CargoCompact: View {
    let cargo: CargoResponse
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("CARGO")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(cargo.used)/\(cargo.capacity)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: cargo.capacity > 0 ? Double(cargo.used) / Double(cargo.capacity) : 0)
                    .tint(.purple)

                if cargo.cargo.isEmpty {
                    Text("Empty")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(cargo.cargo.prefix(3)) { item in
                        HStack {
                            Text(item.displayName)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text("x\(item.quantity)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    if cargo.cargo.count > 3 {
                        Text("+\(cargo.cargo.count - 3) more items")
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
