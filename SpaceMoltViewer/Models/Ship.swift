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
    let baseShieldRecharge: Int?
    let baseArmor: Int
    let baseSpeed: Double
    let baseFuel: Int
    let cargoCapacity: Int
    let cpuCapacity: Int
    let powerCapacity: Int
    let weaponSlots: Int
    let defenseSlots: Int
    let utilitySlots: Int
    let defaultModules: [String]?
    let requiredSkills: [String: Int]?

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
    let quality: Int
    let qualityGrade: String
    let wear: Int
    let wearStatus: String

    // Module-type-specific stats (all optional)
    let miningPower: Int?
    let miningRange: Int?
    let damage: Int?
    let fireRate: Double?
    let range: Int?
    let shieldBonus: Int?
    let armorBonus: Int?
    let speedBonus: Double?
    let scanPower: Int?
    let repairPower: Int?
    let cargoBonusPercent: Int?
    let fuelEfficiency: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, type, quality, wear, damage, range
        case typeId = "type_id"
        case cpuUsage = "cpu_usage"
        case powerUsage = "power_usage"
        case qualityGrade = "quality_grade"
        case wearStatus = "wear_status"
        case miningPower = "mining_power"
        case miningRange = "mining_range"
        case fireRate = "fire_rate"
        case shieldBonus = "shield_bonus"
        case armorBonus = "armor_bonus"
        case speedBonus = "speed_bonus"
        case scanPower = "scan_power"
        case repairPower = "repair_power"
        case cargoBonusPercent = "cargo_bonus_percent"
        case fuelEfficiency = "fuel_efficiency"
    }

    /// Summary of this module's key stat for display
    var statSummary: String? {
        var parts: [String] = []
        if let d = damage { parts.append("Dmg: \(d)") }
        if let fr = fireRate { parts.append("Rate: \(String(format: "%.1f", fr))") }
        if let mp = miningPower { parts.append("Mining: \(mp)") }
        if let mr = miningRange { parts.append("Range: \(mr)") }
        if let sb = shieldBonus { parts.append("Shield: +\(sb)") }
        if let ab = armorBonus { parts.append("Armor: +\(ab)") }
        if let sp = speedBonus { parts.append("Speed: +\(String(format: "%.1f", sp))") }
        if let sc = scanPower { parts.append("Scan: \(sc)") }
        if let rp = repairPower { parts.append("Repair: \(rp)") }
        if let r = range { parts.append("Range: \(r)") }
        return parts.isEmpty ? nil : parts.joined(separator: "  ")
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
