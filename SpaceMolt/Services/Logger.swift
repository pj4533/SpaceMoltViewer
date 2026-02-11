import Foundation
import OSLog

/// Centralized logging system for SpaceMolt
/// Usage: SMLog.network.info("Message")
public enum SMLog {
    private static let subsystem = "com.saygoodnight.SpaceMolt"

    public static let general = Logger(subsystem: subsystem, category: "General")
    public static let network = Logger(subsystem: subsystem, category: "Network")
    public static let auth = Logger(subsystem: subsystem, category: "Auth")
    public static let polling = Logger(subsystem: subsystem, category: "Polling")
    public static let api = Logger(subsystem: subsystem, category: "API")
    public static let keychain = Logger(subsystem: subsystem, category: "Keychain")
    public static let ui = Logger(subsystem: subsystem, category: "UI")
    public static let map = Logger(subsystem: subsystem, category: "Map")
    public static let decode = Logger(subsystem: subsystem, category: "Decode")
}
