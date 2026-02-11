import Foundation

struct PublicMapResponse: Decodable, Sendable {
    let systems: [MapSystem]
}

struct MapSystem: Decodable, Sendable, Identifiable {
    let id: String
    let name: String
    let x: Double
    let y: Double
    let empire: String?
    let empireColor: String?
    let connections: [String]?
    let policeLevel: Int?
    let type: String?
    let isHome: Bool?
    let isStronghold: Bool?
    let online: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, x, y, empire, connections, type, online
        case empireColor = "empire_color"
        case policeLevel = "police_level"
        case isHome = "is_home"
        case isStronghold = "is_stronghold"
    }
}
