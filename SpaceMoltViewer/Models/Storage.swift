import Foundation

struct StorageResponse: Decodable, Sendable {
    let credits: Int
    let items: [StorageItem]
    let stationId: String
    let stationName: String?

    enum CodingKeys: String, CodingKey {
        case credits, items
        case stationId = "station_id"
        case stationName = "station_name"
    }

    var displayName: String {
        stationName ?? stationId
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
