import Foundation

struct WelcomePayload: Decodable, Sendable {
    let version: String?
    let tickRate: Int?
    let currentTick: Int?
    let serverTime: Int?

    enum CodingKeys: String, CodingKey {
        case version
        case tickRate = "tick_rate"
        case currentTick = "current_tick"
        case serverTime = "server_time"
    }
}

struct StateUpdatePayload: Decodable, Sendable {
    let tick: Int
    let player: Player
    let ship: ShipOverview
    let nearby: [NearbyPlayer]?
    let inCombat: Bool?
    let travelProgress: Double?
    let travelDestination: String?
    let travelType: String?
    let travelArrivalTick: Int?

    enum CodingKeys: String, CodingKey {
        case tick, player, ship, nearby
        case inCombat = "in_combat"
        case travelProgress = "travel_progress"
        case travelDestination = "travel_destination"
        case travelType = "travel_type"
        case travelArrivalTick = "travel_arrival_tick"
    }
}

struct ChatMessagePayload: Decodable, Sendable {
    let id: String?
    let channel: String?
    let sender: String?
    let senderId: String?
    let content: String?
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case id, channel, sender, content, timestamp
        case senderId = "sender_id"
    }
}

struct CombatUpdatePayload: Decodable, Sendable {
    let tick: Int?
    let attacker: String?
    let target: String?
    let damage: Int?
    let damageType: String?
    let shieldHit: Bool?
    let hullHit: Bool?
    let destroyed: Bool?

    enum CodingKeys: String, CodingKey {
        case tick, attacker, target, damage, destroyed
        case damageType = "damage_type"
        case shieldHit = "shield_hit"
        case hullHit = "hull_hit"
    }
}

struct MiningYieldPayload: Decodable, Sendable {
    let resourceId: String?
    let quantity: Int?
    let remaining: Int?

    enum CodingKeys: String, CodingKey {
        case quantity, remaining
        case resourceId = "resource_id"
    }
}

struct SkillLevelUpPayload: Decodable, Sendable {
    let skillId: String?
    let newLevel: Int?
    let xpGained: Int?

    enum CodingKeys: String, CodingKey {
        case skillId = "skill_id"
        case newLevel = "new_level"
        case xpGained = "xp_gained"
    }
}

struct PoiEventPayload: Decodable, Sendable {
    let username: String?
    let poiName: String?
    let poiId: String?

    enum CodingKeys: String, CodingKey {
        case username
        case poiName = "poi_name"
        case poiId = "poi_id"
    }
}

struct PlayerDiedPayload: Decodable, Sendable {
    let killer: String?
    let respawnBase: String?
    let cloneCost: Int?
    let insurancePayout: Int?
    let newShipClass: String?

    enum CodingKeys: String, CodingKey {
        case killer
        case respawnBase = "respawn_base"
        case cloneCost = "clone_cost"
        case insurancePayout = "insurance_payout"
        case newShipClass = "new_ship_class"
    }
}

struct PirateWarningPayload: Decodable, Sendable {
    let pirateName: String?
    let pirateId: String?
    let pirateTier: String?
    let isBoss: Bool?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case message
        case pirateName = "pirate_name"
        case pirateId = "pirate_id"
        case pirateTier = "pirate_tier"
        case isBoss = "is_boss"
    }
}

struct PirateCombatPayload: Decodable, Sendable {
    let pirateName: String?
    let pirateId: String?
    let pirateTier: String?
    let isBoss: Bool?
    let damage: Int?
    let damageType: String?
    let yourHull: Int?
    let yourMaxHull: Int?
    let yourShield: Int?

    enum CodingKeys: String, CodingKey {
        case damage
        case pirateName = "pirate_name"
        case pirateId = "pirate_id"
        case pirateTier = "pirate_tier"
        case isBoss = "is_boss"
        case damageType = "damage_type"
        case yourHull = "your_hull"
        case yourMaxHull = "your_max_hull"
        case yourShield = "your_shield"
    }
}

struct PirateDestroyedPayload: Decodable, Sendable {
    let pirateName: String?
    let pirateId: String?
    let pirateTier: String?
    let isBoss: Bool?
    let combatXp: Int?
    let creditsEarned: Int?

    enum CodingKeys: String, CodingKey {
        case pirateName = "pirate_name"
        case pirateId = "pirate_id"
        case pirateTier = "pirate_tier"
        case isBoss = "is_boss"
        case combatXp = "combat_xp"
        case creditsEarned = "credits_earned"
    }
}

struct ErrorPayload: Decodable, Sendable {
    let message: String?
    let code: String?
}

struct OkActionPayload: Decodable, Sendable {
    let action: String
    let destination: String?
    let base: String?
    let system: String?
    let target: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case action, destination, base, system, target, message
    }
}
