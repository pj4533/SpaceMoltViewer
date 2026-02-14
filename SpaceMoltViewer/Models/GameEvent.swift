import Foundation
import SwiftUI

enum GameEventCategory: String, Sendable {
    case tick, combat, mining, navigation, skill, trade, pirate, police, drone, scan, base, system, info, broadcast

    var emoji: String {
        switch self {
        case .tick: return "~"
        case .combat: return "!"
        case .mining: return "*"
        case .navigation: return ">"
        case .skill: return "^"
        case .trade: return "$"
        case .pirate: return "X"
        case .police: return "#"
        case .drone: return "&"
        case .scan: return "?"
        case .base: return "+"
        case .system: return "-"
        case .info: return "i"
        case .broadcast: return "!"
        }
    }

    var color: Color {
        switch self {
        case .combat: return .red
        case .mining: return .orange
        case .navigation: return .cyan
        case .skill: return .green
        case .trade: return .yellow
        case .pirate: return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .police: return .purple
        case .drone: return .teal
        case .scan: return .indigo
        case .base: return .brown
        case .system, .tick: return .gray
        case .info: return .secondary
        case .broadcast: return .yellow
        }
    }
}

struct GameEvent: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let category: GameEventCategory
    let title: String
    let detail: String?
    let rawType: String
}
