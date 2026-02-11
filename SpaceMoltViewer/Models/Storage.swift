import Foundation

struct StorageResponse: Decodable, Sendable {
    let credits: Int
    let items: [StorageItem]
    let baseId: String

    enum CodingKeys: String, CodingKey {
        case credits, items
        case baseId = "base_id"
    }

    var displayName: String {
        baseId
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

struct StorageItem: Decodable, Sendable, Identifiable {
    let itemId: String
    let name: String
    let quantity: Int

    var id: String { itemId }

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case name, quantity
    }
}
