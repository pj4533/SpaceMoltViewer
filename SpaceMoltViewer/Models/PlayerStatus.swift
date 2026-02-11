import Foundation

struct PlayerStatusResponse: Decodable, Sendable {
    let player: Player
    let ship: ShipOverview
}

struct Player: Decodable, Sendable {
    let id: String
    let username: String
    let empire: String
    let credits: Int
    let createdAt: String
    let lastLoginAt: String
    let lastActiveAt: String
    let statusMessage: String
    let clanTag: String
    let primaryColor: String
    let secondaryColor: String
    let anonymous: Bool
    let isCloaked: Bool
    let currentShipId: String
    let currentSystem: String
    let currentPoi: String
    let homeBase: String
    let skills: [String: Int]
    let skillXp: [String: Int]
    let experience: Int
    let stats: PlayerStats
    let discoveredSystems: [String: DiscoveredSystem]?
    let dockedAtBase: String?

    enum CodingKeys: String, CodingKey {
        case id, username, empire, credits, experience, stats, skills, anonymous
        case createdAt = "created_at"
        case lastLoginAt = "last_login_at"
        case lastActiveAt = "last_active_at"
        case statusMessage = "status_message"
        case clanTag = "clan_tag"
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
        case isCloaked = "is_cloaked"
        case currentShipId = "current_ship_id"
        case currentSystem = "current_system"
        case currentPoi = "current_poi"
        case homeBase = "home_base"
        case skillXp = "skill_xp"
        case discoveredSystems = "discovered_systems"
        case dockedAtBase = "docked_at_base"
    }
}

struct PlayerStats: Decodable, Sendable {
    let creditsEarned: Int
    let creditsSpent: Int
    let shipsDestroyed: Int
    let shipsLost: Int
    let piratesDestroyed: Int
    let basesDestroyed: Int
    let oreMined: Int
    let itemsCrafted: Int
    let tradesCompleted: Int
    let systemsExplored: Int
    let distanceTraveled: Int
    let timePlayed: Int

    enum CodingKeys: String, CodingKey {
        case creditsEarned = "credits_earned"
        case creditsSpent = "credits_spent"
        case shipsDestroyed = "ships_destroyed"
        case shipsLost = "ships_lost"
        case piratesDestroyed = "pirates_destroyed"
        case basesDestroyed = "bases_destroyed"
        case oreMined = "ore_mined"
        case itemsCrafted = "items_crafted"
        case tradesCompleted = "trades_completed"
        case systemsExplored = "systems_explored"
        case distanceTraveled = "distance_traveled"
        case timePlayed = "time_played"
    }
}

struct DiscoveredSystem: Decodable, Sendable {
    let systemId: String
    let discoveredAt: String

    enum CodingKeys: String, CodingKey {
        case systemId = "system_id"
        case discoveredAt = "discovered_at"
    }
}

struct ShipOverview: Decodable, Sendable {
    let id: String
    let name: String
    let classId: String
    let hull: Int
    let maxHull: Int
    let shield: Int
    let maxShield: Int
    let armor: Int
    let fuel: Int
    let maxFuel: Int
    let speed: Double
    let cargoUsed: Int
    let cargoCapacity: Int
    let cpuUsed: Int
    let cpuMax: Int
    let powerUsed: Int
    let powerMax: Int
    let cargo: [CargoItem]?

    enum CodingKeys: String, CodingKey {
        case id, name, hull, shield, armor, fuel, speed, cargo
        case classId = "class_id"
        case maxHull = "max_hull"
        case maxShield = "max_shield"
        case maxFuel = "max_fuel"
        case cargoUsed = "cargo_used"
        case cargoCapacity = "cargo_capacity"
        case cpuUsed = "cpu_used"
        case cpuMax = "cpu_capacity"
        case powerUsed = "power_used"
        case powerMax = "power_capacity"
    }

    var hullPercent: Double {
        guard maxHull > 0 else { return 0 }
        return Double(hull) / Double(maxHull)
    }

    var shieldPercent: Double {
        guard maxShield > 0 else { return 0 }
        return Double(shield) / Double(maxShield)
    }

    var fuelPercent: Double {
        guard maxFuel > 0 else { return 0 }
        return Double(fuel) / Double(maxFuel)
    }

    var cargoPercent: Double {
        guard cargoCapacity > 0 else { return 0 }
        return Double(cargoUsed) / Double(cargoCapacity)
    }
}
