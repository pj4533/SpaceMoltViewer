import Foundation

extension String {
    var displayFormatted: String {
        replacingOccurrences(of: "_", with: " ").capitalized
    }

    var isoTimeOnly: String {
        guard let tIndex = firstIndex(of: "T") else { return self }
        let timeStr = self[index(after: tIndex)...]
        let endIndex = timeStr.firstIndex(of: "Z") ?? timeStr.firstIndex(of: "+") ?? timeStr.endIndex
        return String(timeStr[..<endIndex].prefix(5))
    }

    var isLawless: Bool {
        contains("Lawless") || contains("no police")
    }
}
