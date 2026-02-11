import Foundation

struct NotificationsResponse: Decodable, Sendable {
    let count: Int
    let currentTick: Int
    let notifications: [GameNotification]
    let remaining: Int
    let timestamp: Int

    enum CodingKeys: String, CodingKey {
        case count, notifications, remaining, timestamp
        case currentTick = "current_tick"
    }
}

struct GameNotification: Decodable, Sendable, Identifiable {
    let id: String?
    let type: String?
    let message: String?
    let timestamp: String?
}
