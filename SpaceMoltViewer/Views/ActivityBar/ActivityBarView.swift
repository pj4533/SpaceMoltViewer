import SwiftUI

struct ActivityBarView: View {
    let gameStateManager: GameStateManager
    @Binding var selectedTab: BottomBarTab

    var body: some View {
        VStack(spacing: 0) {
            // Tab strip header
            HStack(spacing: 0) {
                ForEach(BottomBarTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.caption2)
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedTab == tab ? .white.opacity(0.1) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.bar)

            Divider()

            // Content
            switch selectedTab {
            case .events:
                EventsFeedView(gameStateManager: gameStateManager)
            case .chat:
                ChatFeedView(gameStateManager: gameStateManager)
            case .log:
                LogFeedView(gameStateManager: gameStateManager)
            }
        }
    }
}
