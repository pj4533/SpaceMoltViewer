import Foundation

struct OwnedShipsResponse: Decodable, Sendable {
    let activeShipClass: String
    let activeShipId: String
    let count: Int
    let ships: [OwnedShip]

    enum CodingKeys: String, CodingKey {
        case count, ships
        case activeShipClass = "active_ship_class"
        case activeShipId = "active_ship_id"
    }
}

struct OwnedShip: Decodable, Sendable, Identifiable {
    let shipId: String
    let classId: String
    let className: String
    let isActive: Bool
    let location: String
    let locationBaseId: String?
    let hull: String
    let fuel: String
    let cargoUsed: Int
    let modules: Int

    var id: String { shipId }

    enum CodingKeys: String, CodingKey {
        case hull, fuel, modules, location
        case shipId = "ship_id"
        case classId = "class_id"
        case className = "class_name"
        case isActive = "is_active"
        case locationBaseId = "location_base_id"
        case cargoUsed = "cargo_used"
    }
}
