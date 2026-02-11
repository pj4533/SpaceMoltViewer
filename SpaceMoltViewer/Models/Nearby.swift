import Foundation

struct NearbyResponse: Decodable, Sendable {
    let count: Int
    let nearby: [NearbyPlayer]
    let pirateCount: Int
    let pirates: [NearbyPirate]
    let poiId: String

    enum CodingKeys: String, CodingKey {
        case count, nearby, pirates
        case pirateCount = "pirate_count"
        case poiId = "poi_id"
    }
}

struct NearbyPlayer: Decodable, Sendable, Identifiable {
    let playerId: String
    let anonymous: Bool
    let inCombat: Bool?
    let username: String?
    let shipClass: String?
    let clanTag: String?
    let statusMessage: String?
    let primaryColor: String?
    let secondaryColor: String?

    var id: String { playerId }

    var displayName: String {
        if anonymous { return "Anonymous" }
        return username ?? "Unknown"
    }

    enum CodingKeys: String, CodingKey {
        case anonymous, username
        case playerId = "player_id"
        case inCombat = "in_combat"
        case shipClass = "ship_class"
        case clanTag = "clan_tag"
        case statusMessage = "status_message"
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
    }
}

struct NearbyPirate: Decodable, Sendable, Identifiable {
    let id: String
    let name: String
    let shipClass: String
    let hullPercent: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case shipClass = "ship_class"
        case hullPercent = "hull_percent"
    }
}
