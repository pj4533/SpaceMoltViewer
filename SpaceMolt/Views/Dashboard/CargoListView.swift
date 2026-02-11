import SwiftUI

struct CargoListView: View {
    let cargo: CargoResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Cargo")
                    .font(.headline)
                Spacer()
                Text("\(cargo.used)/\(cargo.capacity)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if cargo.cargo.isEmpty {
                Text("Empty")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(cargo.cargo) { item in
                    HStack {
                        Text(item.displayName)
                            .font(.subheadline)
                        Spacer()
                        Text("x\(item.quantity)")
                            .font(.subheadline.monospacedDigit())
                        Text("(\(item.totalSize) slots)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
