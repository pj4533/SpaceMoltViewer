import Foundation

struct ShipDetailResponse: Decodable, Sendable {
    let cargoMax: Int
    let cargoUsed: Int
    let shipClass: ShipClass
    let modules: [ShipModule]
    let ship: ShipStats
    let stats: ShipResourceStats?

    enum CodingKeys: String, CodingKey {
        case modules, ship, stats
        case cargoMax = "cargo_max"
        case cargoUsed = "cargo_used"
        case shipClass = "class"
    }
}

struct ShipClass: Decodable, Sendable {
    let id: String
    let name: String
    let description: String
    let shipCategory: String
    let price: Int
    let baseHull: Int
    let baseShield: Int
    let baseShieldRecharge: Int
    let baseArmor: Int
    let baseSpeed: Double
    let baseFuel: Int
    let cargoCapacity: Int
    let cpuCapacity: Int
    let powerCapacity: Int
    let weaponSlots: Int
    let defenseSlots: Int
    let utilitySlots: Int
    let defaultModules: [String]
    let requiredSkills: [String: Int]

    enum CodingKeys: String, CodingKey {
        case id, name, description, price
        case shipCategory = "class"
        case baseHull = "base_hull"
        case baseShield = "base_shield"
        case baseShieldRecharge = "base_shield_recharge"
        case baseArmor = "base_armor"
        case baseSpeed = "base_speed"
        case baseFuel = "base_fuel"
        case cargoCapacity = "cargo_capacity"
        case cpuCapacity = "cpu_capacity"
        case powerCapacity = "power_capacity"
        case weaponSlots = "weapon_slots"
        case defenseSlots = "defense_slots"
        case utilitySlots = "utility_slots"
        case defaultModules = "default_modules"
        case requiredSkills = "required_skills"
    }
}

struct ShipModule: Decodable, Sendable, Identifiable {
    let id: String
    let typeId: String
    let name: String
    let type: String
    let cpuUsage: Int
    let powerUsage: Int
    let miningPower: Int?
    let miningRange: Int?
    let quality: Int
    let qualityGrade: String
    let wear: Int
    let wearStatus: String

    enum CodingKeys: String, CodingKey {
        case id, name, type, quality, wear
        case typeId = "type_id"
        case cpuUsage = "cpu_usage"
        case powerUsage = "power_usage"
        case miningPower = "mining_power"
        case miningRange = "mining_range"
        case qualityGrade = "quality_grade"
        case wearStatus = "wear_status"
    }
}

struct ShipStats: Decodable, Sendable {
    let armor: Int
    let fuel: Int
    let hull: Int
    let maxFuel: Int
    let maxHull: Int
    let maxShield: Int
    let shield: Int
    let speed: Double
    let cpuUsed: Int?
    let cpuCapacity: Int?
    let powerUsed: Int?
    let powerCapacity: Int?

    enum CodingKeys: String, CodingKey {
        case armor, fuel, hull, shield, speed
        case maxFuel = "max_fuel"
        case maxHull = "max_hull"
        case maxShield = "max_shield"
        case cpuUsed = "cpu_used"
        case cpuCapacity = "cpu_capacity"
        case powerUsed = "power_used"
        case powerCapacity = "power_capacity"
    }
}

struct ShipResourceStats: Decodable, Sendable {
    let cpuMax: Int
    let cpuUsed: Int
    let powerMax: Int
    let powerUsed: Int

    enum CodingKeys: String, CodingKey {
        case cpuMax = "cpu_max"
        case cpuUsed = "cpu_used"
        case powerMax = "power_max"
        case powerUsed = "power_used"
    }
}
