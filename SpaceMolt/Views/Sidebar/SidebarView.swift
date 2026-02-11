import SwiftUI

enum SidebarTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case ship = "Ship"
    case map = "Galaxy Map"
    case skills = "Skills"
    case missions = "Missions"
    case social = "Social"
    case log = "Captain's Log"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.50percent"
        case .ship: return "airplane"
        case .map: return "map"
        case .skills: return "star.fill"
        case .missions: return "target"
        case .social: return "bubble.left.and.bubble.right"
        case .log: return "book"
        case .settings: return "gear"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTab: SidebarTab?

    var body: some View {
        List(SidebarTab.allCases, selection: $selectedTab) { tab in
            Label(tab.rawValue, systemImage: tab.icon)
                .tag(tab)
        }
        .listStyle(.sidebar)
        .navigationTitle("SpaceMolt")
    }
}
