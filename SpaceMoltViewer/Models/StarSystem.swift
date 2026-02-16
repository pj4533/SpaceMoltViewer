import Foundation

struct SystemResponse: Decodable, Sendable {
    let system: StarSystem
    let securityStatus: String

    /// POIs are now inside the system object
    var pois: [PointOfInterest] { system.pois }

    enum CodingKeys: String, CodingKey {
        case system
        case securityStatus = "security_status"
    }
}

struct SystemConnection: Decodable, Sendable, Identifiable {
    let systemId: String
    let name: String
    let distance: Int

    var id: String { systemId }

    enum CodingKeys: String, CodingKey {
        case systemId = "system_id"
        case name, distance
    }
}

struct StarSystem: Decodable, Sendable {
    let id: String
    let name: String
    let description: String
    let policeLevel: Int?
    let empire: String?
    let securityStatus: String?
    let connections: [SystemConnection]
    let pois: [PointOfInterest]

    enum CodingKeys: String, CodingKey {
        case id, name, description, connections, pois, empire
        case policeLevel = "police_level"
        case securityStatus = "security_status"
    }
}

struct Position: Decodable, Sendable {
    let x: Double
    let y: Double
}

struct PoiResource: Decodable, Sendable, Identifiable {
    let resourceId: String
    let richness: Int
    let remaining: Int?

    var id: String { resourceId }

    /// Whether this resource has a finite supply (-1 or nil = infinite)
    var isFinite: Bool {
        guard let remaining else { return false }
        return remaining >= 0
    }

    enum CodingKeys: String, CodingKey {
        case resourceId = "resource_id"
        case richness, remaining
    }
}

struct PointOfInterest: Decodable, Sendable, Identifiable {
    let id: String
    let systemId: String?
    let type: String
    let name: String
    let description: String?
    let position: Position?
    let resources: [PoiResource]?
    let hasBase: Bool?
    let baseId: String?
    let baseName: String?
    let online: Int?

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

    /// POI types that can have mineable/collectible resources
    static let resourcePoiTypes: Set<String> = [
        "asteroid_belt", "gas_cloud", "ice_field", "planet", "relic"
    ]

    var canHaveResources: Bool {
        Self.resourcePoiTypes.contains(type)
    }

    enum CodingKeys: String, CodingKey {
        case id, type, name, description, position, resources, online
        case systemId = "system_id"
        case hasBase = "has_base"
        case baseId = "base_id"
        case baseName = "base_name"
    }
}

struct PoiDetailResponse: Decodable, Sendable {
    let poi: PointOfInterest
    let resources: [PoiResource]?
}
