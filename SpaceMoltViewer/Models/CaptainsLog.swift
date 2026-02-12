import Foundation

struct CaptainsLogResponse: Sendable {
    let entries: [LogEntry]
    let totalCount: Int
    let maxEntries: Int
}

struct CaptainsLogPageResponse: Decodable, Sendable {
    let entry: LogEntry
    let index: Int
    let totalCount: Int
    let maxEntries: Int
    let hasNext: Bool
    let hasPrev: Bool

    enum CodingKeys: String, CodingKey {
        case entry, index
        case totalCount = "total_count"
        case maxEntries = "max_entries"
        case hasNext = "has_next"
        case hasPrev = "has_prev"
    }
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
