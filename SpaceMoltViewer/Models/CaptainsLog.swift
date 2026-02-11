import Foundation

struct CaptainsLogResponse: Decodable, Sendable {
    let entries: [LogEntry]
}

struct LogEntry: Decodable, Sendable, Identifiable {
    let index: Int
    let entry: String
    let createdAt: String

    var id: Int { index }

    enum CodingKeys: String, CodingKey {
        case index, entry
        case createdAt = "created_at"
    }
}
