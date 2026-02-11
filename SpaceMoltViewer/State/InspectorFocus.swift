import Foundation

enum InspectorFocus: Equatable {
    case none
    case systemDetail(String)
    case shipDetail
    case missionDetail(String)
    case skillsOverview
    case cargoDetail
    case nearbyDetail
    case storageDetail
}
