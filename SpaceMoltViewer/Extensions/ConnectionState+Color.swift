import SwiftUI

extension ConnectionState {
    var color: Color {
        switch self {
        case .connected: return .green
        case .connecting, .reconnecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}
