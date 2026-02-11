import SwiftUI

struct InspectorPanelView: View {
    let focus: InspectorFocus
    let gameStateManager: GameStateManager
    let mapViewModel: MapViewModel
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text(headerTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if focus != .none {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            // Content
            switch focus {
            case .none:
                InspectorEmptyView(gameStateManager: gameStateManager)
            case .systemDetail(let id):
                SystemInspectorView(systemId: id, mapViewModel: mapViewModel, gameStateManager: gameStateManager)
            case .shipDetail:
                ShipInspectorView(gameStateManager: gameStateManager)
            case .missionDetail(let id):
                MissionInspectorView(missionId: id, gameStateManager: gameStateManager)
            case .skillsOverview:
                SkillsInspectorView(gameStateManager: gameStateManager)
            case .cargoDetail:
                CargoInspectorView(gameStateManager: gameStateManager)
            case .nearbyDetail:
                NearbyInspectorView(gameStateManager: gameStateManager)
            case .storageDetail:
                StorageInspectorView(gameStateManager: gameStateManager)
            }
        }
    }

    private var headerTitle: String {
        switch focus {
        case .none: return "INSPECTOR"
        case .systemDetail: return "SYSTEM"
        case .shipDetail: return "SHIP"
        case .missionDetail: return "MISSION"
        case .skillsOverview: return "SKILLS"
        case .cargoDetail: return "CARGO"
        case .nearbyDetail: return "NEARBY"
        case .storageDetail: return "STORAGE"
        }
    }
}
