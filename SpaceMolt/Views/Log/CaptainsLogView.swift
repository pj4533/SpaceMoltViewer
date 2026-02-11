import SwiftUI

struct CaptainsLogView: View {
    let viewModel: LogViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if viewModel.logEntries.isEmpty {
                    EmptyStateView(
                        icon: "book",
                        title: "No Log Entries",
                        message: "The captain's log is empty."
                    )
                } else {
                    HStack {
                        Text("Captain's Log")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.logEntries.count) entries")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            Task { await viewModel.refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }

                    ForEach(viewModel.logEntries) { entry in
                        LogEntryView(entry: entry)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Captain's Log")
    }
}
