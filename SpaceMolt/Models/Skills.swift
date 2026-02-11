import Foundation

struct SkillsResponse: Decodable, Sendable {
    let playerSkillCount: Int
    let playerSkills: [PlayerSkill]
    let totalSkillCount: Int?
    let allSkills: [String: SkillDefinition]?

    enum CodingKeys: String, CodingKey {
        case playerSkillCount = "player_skill_count"
        case playerSkills = "player_skills"
        case totalSkillCount = "total_skill_count"
        case allSkills = "skills"
    }
}

struct PlayerSkill: Decodable, Sendable, Identifiable {
    let skillId: String
    let name: String
    let category: String
    let level: Int
    let currentXp: Int
    let nextLevelXp: Int
    let maxLevel: Int

    var id: String { skillId }

    var progress: Double {
        guard nextLevelXp > 0 else { return 1.0 }
        return Double(currentXp) / Double(nextLevelXp)
    }

    enum CodingKeys: String, CodingKey {
        case name, category, level
        case skillId = "skill_id"
        case currentXp = "current_xp"
        case nextLevelXp = "next_level_xp"
        case maxLevel = "max_level"
    }
}

struct SkillDefinition: Decodable, Sendable, Identifiable {
    let skillId: String
    let name: String
    let category: String
    let description: String
    let maxLevel: Int
    let bonusPerLevel: [String: Int]?
    let trainingSource: String?
    let prerequisites: [String: Int]?

    var id: String { skillId }

    enum CodingKeys: String, CodingKey {
        case name, category, description
        case skillId = "id"
        case maxLevel = "max_level"
        case bonusPerLevel = "bonus_per_level"
        case trainingSource = "training_source"
        case prerequisites = "required_skills"
    }
}
