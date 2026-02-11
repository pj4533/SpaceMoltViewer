import SwiftUI

struct CargoInspectorView: View {
    let gameStateManager: GameStateManager

    private var cargo: CargoResponse? { gameStateManager.cargo }

    var body: some View {
        ScrollView {
            if let cargo {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Cargo")
                            .font(.title3.bold())
                        Spacer()
                        Text("\(cargo.used)/\(cargo.capacity)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: cargo.capacity > 0 ? Double(cargo.used) / Double(cargo.capacity) : 0)
                        .tint(.purple)

                    Divider()

                    if cargo.cargo.isEmpty {
                        Text("Cargo hold is empty")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(cargo.cargo) { item in
                            HStack {
                                Text(item.displayName)
                                    .font(.caption)
                                Spacer()
                                Text("x\(item.quantity)")
                                    .font(.caption.monospacedDigit())
                                Text("(\(item.totalSize) slots)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(12)
            } else {
                Text("No cargo data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
    }
}
