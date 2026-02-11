import Foundation

struct OrdersResponse: Decodable, Sendable {
    let orders: [ExchangeOrder]
}

struct ExchangeOrder: Decodable, Sendable, Identifiable {
    let id: String
    let type: String
    let itemId: String
    let priceEach: Int
    let quantity: Int
    let quantityFilled: Int
    let quantityRemaining: Int
    let stationId: String
    let createdAt: String

    var fillProgress: Double {
        guard quantity > 0 else { return 0 }
        return Double(quantityFilled) / Double(quantity)
    }

    enum CodingKeys: String, CodingKey {
        case id, type, quantity
        case itemId = "item_id"
        case priceEach = "price_each"
        case quantityFilled = "quantity_filled"
        case quantityRemaining = "quantity_remaining"
        case stationId = "station_id"
        case createdAt = "created_at"
    }
}
