import Foundation

struct MissionsResponse: Decodable, Sendable {
    let missions: [Mission]?
    let totalCount: Int
    let maxMissions: Int

    enum CodingKeys: String, CodingKey {
        case missions
        case totalCount = "total_count"
        case maxMissions = "max_missions"
    }
}

struct Mission: Decodable, Sendable, Identifiable {
    let id: String
    let type: String
    let title: String
    let description: String
    let difficulty: Int
    let objectives: [MissionObjective]
    let rewards: MissionRewards
    let expiresAt: String?
    let ticksRemaining: Int?

    enum CodingKeys: String, CodingKey {
        case id, type, title, description, difficulty, objectives, rewards
        case expiresAt = "expires_at"
        case ticksRemaining = "ticks_remaining"
    }
}

struct MissionObjective: Decodable, Sendable, Identifiable {
    let description: String
    let current: Int
    let required: Int
    let completed: Bool

    var id: String { description }

    var progress: Double {
        guard required > 0 else { return completed ? 1.0 : 0.0 }
        return Double(current) / Double(required)
    }
}

struct MissionRewards: Decodable, Sendable {
    let credits: Int?
    let skillXp: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case credits
        case skillXp = "skill_xp"
    }
}
