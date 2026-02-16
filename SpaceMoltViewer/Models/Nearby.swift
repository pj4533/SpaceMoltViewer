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
    let playerId: String?
    let anonymous: Bool
    let inCombat: Bool?
    let username: String?
    let shipClass: String?
    let clanTag: String?
    let statusMessage: String?
    let primaryColor: String?
    let secondaryColor: String?

    var id: String { playerId ?? username ?? "anon-\(shipClass ?? "unknown")" }

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
    let pirateId: String
    let name: String
    let hull: Int
    let maxHull: Int
    let shield: Int
    let maxShield: Int
    let tier: String
    let status: String
    let isBoss: Bool

    var id: String { pirateId }

    var hullPercent: Int {
        guard maxHull > 0 else { return 0 }
        return Int(Double(hull) / Double(maxHull) * 100)
    }

    var shieldPercent: Int {
        guard maxShield > 0 else { return 0 }
        return Int(Double(shield) / Double(maxShield) * 100)
    }

    enum CodingKeys: String, CodingKey {
        case name, hull, shield, tier, status
        case pirateId = "pirate_id"
        case maxHull = "max_hull"
        case maxShield = "max_shield"
        case isBoss = "is_boss"
    }
}
