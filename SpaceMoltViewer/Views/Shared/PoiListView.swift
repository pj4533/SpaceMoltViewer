import SwiftUI

struct PoiListView: View {
    let pois: [PointOfInterest]
    var poiResources: [String: [PoiResource]] = [:]

    var body: some View {
        ForEach(pois) { poi in
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: poi.poiIcon)
                        .frame(width: 14)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(poi.name)
                        .font(.caption)
                    Spacer()
                    Text(poi.type)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Show resources (inline from get_system, or fetched via get_poi)
                let resources = poi.resources ?? poiResources[poi.id]
                if let resources, !resources.isEmpty {
                    ForEach(resources) { resource in
                        HStack(spacing: 4) {
                            Image(systemName: "cube.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.orange)
                            Text(resource.resourceId.displayFormatted)
                                .font(.caption2)
                            Spacer()
                            ProgressView(value: Double(resource.richness), total: 100)
                                .frame(width: 40)
                                .tint(richnessColor(resource.richness))
                            Text("\(resource.richness)%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .trailing)
                        }
                        .padding(.leading, 20)
                    }
                }
            }
        }
    }

    private func richnessColor(_ richness: Int) -> Color {
        switch richness {
        case 0..<25: return .red
        case 25..<50: return .orange
        case 50..<75: return .yellow
        default: return .green
        }
    }
}
