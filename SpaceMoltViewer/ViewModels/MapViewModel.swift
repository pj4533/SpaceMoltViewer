import Foundation
import CoreGraphics
import OSLog
import Observation

@MainActor @Observable
class MapViewModel {
    let gameStateManager: GameStateManager
    var onFocusChange: ((InspectorFocus) -> Void)?

    var scale: CGFloat = 1.0
    var offset: CGSize = .zero
    private(set) var selectedSystemId: String?

    // Coordinate ranges from plan
    private let minX: Double = -6950
    private let maxX: Double = 6900
    private let minY: Double = -7600
    private let maxY: Double = 6370

    init(gameStateManager: GameStateManager) {
        self.gameStateManager = gameStateManager
        SMLog.map.debug("MapViewModel initialized")
    }

    var systems: [MapSystem] { gameStateManager.publicMap ?? [] }
    var currentSystem: String? { gameStateManager.playerStatus?.player.currentSystem }
    var discoveredSystems: Set<String> {
        guard let discovered = gameStateManager.playerStatus?.player.discoveredSystems else {
            return []
        }
        return Set(discovered.keys)
    }

    var selectedSystem: MapSystem? {
        guard let id = selectedSystemId else { return nil }
        return systems.first { $0.id == id }
    }

    // Normalize game coordinates to screen position
    // Y is NOT flipped — negative Y maps to top of screen (matching web map orientation)
    func normalizedPosition(for system: MapSystem, in size: CGSize) -> CGPoint {
        let nx = (system.x - minX) / (maxX - minX)
        let ny = (system.y - minY) / (maxY - minY)
        return CGPoint(
            x: nx * size.width,
            y: ny * size.height
        )
    }

    func empireColor(for system: MapSystem) -> String {
        if system.isStronghold == true { return "pirate" }
        return system.empire ?? "neutral"
    }

    func isVisited(_ system: MapSystem) -> Bool {
        discoveredSystems.contains(system.id)
    }

    func isCurrent(_ system: MapSystem) -> Bool {
        system.id == currentSystem
    }

    func selectSystem(_ id: String?) {
        selectedSystemId = id
        if let id {
            SMLog.map.debug("Selected system: \(id)")
            onFocusChange?(.systemDetail(id))
        } else {
            SMLog.map.debug("Deselected system")
            onFocusChange?(.none)
        }
    }

    func resetView() {
        SMLog.map.debug("Resetting map view")
        scale = 1.0
        offset = .zero
        selectedSystemId = nil
    }
}
