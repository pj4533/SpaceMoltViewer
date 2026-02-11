import Foundation
import OSLog
import Security

enum KeychainError: Error {
    case saveFailed(OSStatus)
}

struct KeychainService {
    private static let service = "com.saygoodnight.SpaceMolt"
    private static let account = "credentials"

    struct Credentials: Codable, Sendable {
        let username: String
        let password: String
    }

    static func save(credentials: Credentials) throws {
        SMLog.keychain.info("Saving credentials for user: \(credentials.username)")
        let data: Data
        do {
            data = try JSONEncoder().encode(credentials)
        } catch {
            SMLog.decode.error("Failed to encode credentials: \(error)")
            throw error
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let deleteStatus = SecItemDelete(query as CFDictionary)
        SMLog.keychain.debug("Keychain delete existing: \(deleteStatus)")

        var addQuery = query
        addQuery[kSecValueData as String] = data

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            SMLog.keychain.error("Keychain save failed: OSStatus \(status)")
            throw KeychainError.saveFailed(status)
        }
        SMLog.keychain.info("Credentials saved successfully")
    }

    static func load() -> Credentials? {
        SMLog.keychain.debug("Loading credentials from keychain")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            SMLog.keychain.debug("No credentials found in keychain (status: \(status))")
            return nil
        }

        let creds: Credentials
        do {
            creds = try JSONDecoder().decode(Credentials.self, from: data)
        } catch {
            SMLog.keychain.error("Failed to decode credentials from keychain data: \(error)")
            return nil
        }

        SMLog.keychain.info("Credentials loaded for user: \(creds.username)")
        return creds
    }

    static func delete() {
        SMLog.keychain.info("Deleting credentials from keychain")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        SMLog.keychain.debug("Keychain delete: OSStatus \(status)")
    }
}
