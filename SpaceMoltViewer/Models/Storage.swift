import Foundation

struct StorageResponse: Decodable, Sendable {
    let credits: Int
    let items: [StorageItem]
    let locationId: String
    let locationName: String?

    enum CodingKeys: String, CodingKey {
        case credits, items
        // API sends "base_id" but docs said "station_id" — accept either
        case locationId = "base_id"
        case locationName = "station_name"
    }

    var displayName: String {
        locationName ?? locationId
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
