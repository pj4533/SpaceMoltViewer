import Foundation

struct DronesResponse: Decodable, Sendable {
    let drones: [Drone]
    let totalCount: Int
    let bandwidthUsed: Int
    let bandwidthTotal: Int
    let droneCapacity: Int

    enum CodingKeys: String, CodingKey {
        case drones
        case totalCount = "total_count"
        case bandwidthUsed = "bandwidth_used"
        case bandwidthTotal = "bandwidth_total"
        case droneCapacity = "drone_capacity"
    }
}

struct Drone: Decodable, Sendable, Identifiable {
    let id: String
    let type: String?
    let status: String?
    let health: Int?
    let maxHealth: Int?
    let target: String?
    let bandwidth: Int?

    enum CodingKeys: String, CodingKey {
        case id, type, status, health, target, bandwidth
        case maxHealth = "max_health"
    }
}
