import SwiftUI

struct MapControlsView: View {
    @Bindable var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 4) {
            Button {
                withAnimation { viewModel.scale = min(10, viewModel.scale * 1.5) }
            } label: {
                Image(systemName: "plus")
                    .frame(width: 28, height: 28)
            }

            Button {
                withAnimation { viewModel.scale = max(0.5, viewModel.scale / 1.5) }
            } label: {
                Image(systemName: "minus")
                    .frame(width: 28, height: 28)
            }

            Divider()
                .frame(width: 20)

            Button {
                withAnimation { viewModel.resetView() }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 28, height: 28)
            }
        }
        .buttonStyle(.bordered)
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
