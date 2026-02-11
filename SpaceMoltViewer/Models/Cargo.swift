import Foundation

struct CargoResponse: Decodable, Sendable {
    let available: Int
    let capacity: Int
    let used: Int
    let cargo: [CargoItem]
}

struct CargoItem: Decodable, Sendable, Identifiable {
    let itemId: String
    let name: String?
    let quantity: Int
    let size: Int?

    var id: String { itemId }
    var totalSize: Int { quantity * (size ?? 1) }

    var displayName: String {
        if let name { return name }
        return itemId
            .replacingOccurrences(of: "ore_", with: "")
            .replacingOccurrences(of: "item_", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case name, quantity, size
    }
}
