import Foundation
import OSLog

/// Shared JSON decoder that handles Swift Foundation's "Number X is not representable" bug.
/// Tries JSONDecoder first, then falls back to JSONSerialization → PropertyListDecoder
/// which bypasses the buggy text parser entirely.
enum ResilientDecoder {

    /// Decode JSON data, returning nil on failure (matches `try? JSONDecoder().decode(...)` usage).
    static func decodeOrNil<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        // Fast path
        if let result = try? JSONDecoder().decode(type, from: data) {
            return result
        }
        // Plist fallback
        return decodeViaPlist(type, from: data)
    }

    /// Decode JSON data, throwing on failure (matches `try JSONDecoder().decode(...)` usage).
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        // Fast path
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            // Plist fallback
            if let result = decodeViaPlist(type, from: data) {
                return result
            }
            throw error
        }
    }

    // MARK: - Private

    private static func decodeViaPlist<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            return nil
        }
        let cleaned = stripNulls(obj)
        guard let plistData = try? PropertyListSerialization.data(fromPropertyList: cleaned, format: .binary, options: 0) else {
            return nil
        }
        return try? PropertyListDecoder().decode(type, from: plistData)
    }

    private static func stripNulls(_ obj: Any) -> Any {
        switch obj {
        case let dict as [String: Any]:
            var result = [String: Any]()
            for (key, value) in dict {
                if value is NSNull { continue }
                result[key] = stripNulls(value)
            }
            return result
        case let arr as [Any]:
            return arr.filter { !($0 is NSNull) }.map { stripNulls($0) }
        default:
            return obj
        }
    }
}
