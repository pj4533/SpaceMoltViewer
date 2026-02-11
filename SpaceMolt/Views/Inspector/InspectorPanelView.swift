import SwiftUI

struct InspectorPanelView: View {
    let focus: InspectorFocus
    let pollingManager: PollingManager
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
                InspectorEmptyView(pollingManager: pollingManager)
            case .systemDetail(let id):
                SystemInspectorView(systemId: id, mapViewModel: mapViewModel, pollingManager: pollingManager)
            case .shipDetail:
                ShipInspectorView(pollingManager: pollingManager)
            case .missionDetail(let id):
                MissionInspectorView(missionId: id, pollingManager: pollingManager)
            case .skillsOverview:
                SkillsInspectorView(pollingManager: pollingManager)
            case .cargoDetail:
                CargoInspectorView(pollingManager: pollingManager)
            case .nearbyDetail:
                NearbyInspectorView(pollingManager: pollingManager)
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
        }
    }
}
