import Foundation

struct ChatHistoryResponse: Decodable, Sendable {
    let messages: [ChatMessage]
    let hasMore: Bool?

    enum CodingKeys: String, CodingKey {
        case messages
        case hasMore = "has_more"
    }
}

struct ChatMessage: Decodable, Sendable, Identifiable {
    let id: String
    let channel: String
    let senderId: String
    let senderName: String
    let content: String
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case id, channel, content
        case senderId = "sender_id"
        case senderName = "sender"
        case timestamp = "timestamp_utc"
    }
}
