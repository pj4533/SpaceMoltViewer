import SwiftUI

struct SocialView: View {
    @Bindable var viewModel: SocialViewModel

    var body: some View {
        VStack(spacing: 0) {
            Picker("Channel", selection: $viewModel.selectedChannel) {
                ForEach(SocialViewModel.channels, id: \.self) { channel in
                    Text(channel.capitalized).tag(channel)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ChatChannelView(messages: viewModel.messages)
        }
        .navigationTitle("Social")
        .onChange(of: viewModel.selectedChannel) {
            Task { await viewModel.refreshChat() }
        }
    }
}
