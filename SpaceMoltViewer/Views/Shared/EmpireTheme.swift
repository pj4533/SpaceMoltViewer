import SwiftUI

enum EmpireTheme {
    static func color(for empire: String) -> Color {
        switch empire.lowercased() {
        case "solarian": return Color(red: 0.29, green: 0.56, blue: 0.85)
        case "voidborn": return Color(red: 0, green: 1, blue: 1)
        case "crimson": return Color(red: 0.86, green: 0.08, blue: 0.24)
        case "nebula": return Color(red: 1, green: 0.84, blue: 0)
        case "outerrim": return Color(red: 0.25, green: 0.41, blue: 0.88)
        case "pirate": return Color(red: 1, green: 0.2, blue: 0.2)
        case "neutral": return Color(white: 0.65)
        default: return Color(white: 0.65)
        }
    }
}
