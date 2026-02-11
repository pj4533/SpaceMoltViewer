import Foundation

struct SystemResponse: Decodable, Sendable {
    let system: StarSystem
    let pois: [PointOfInterest]
    let securityStatus: String

    enum CodingKeys: String, CodingKey {
        case system, pois
        case securityStatus = "security_status"
    }
}

struct StarSystem: Decodable, Sendable {
    let id: String
    let name: String
    let description: String
    let policeLevel: Int
    let connections: [String]
    let pois: [String]
    let position: Position

    enum CodingKeys: String, CodingKey {
        case id, name, description, connections, pois, position
        case policeLevel = "police_level"
    }
}

struct Position: Decodable, Sendable {
    let x: Double
    let y: Double
}

struct PointOfInterest: Decodable, Sendable, Identifiable {
    let id: String
    let systemId: String
    let type: String
    let name: String
    let description: String?
    let position: Position?

    var poiIcon: String {
        switch type {
        case "sun": return "sun.max.fill"
        case "planet": return "globe"
        case "asteroid_belt": return "circle.hexagongrid"
        case "gas_cloud": return "cloud.fill"
        case "ice_field": return "snowflake"
        case "station": return "building.2.fill"
        case "relic": return "sparkles"
        case "jump_gate": return "arrow.triangle.swap"
        default: return "questionmark.circle"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, name, description, position
        case systemId = "system_id"
    }
}
