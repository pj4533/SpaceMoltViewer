import SwiftUI

struct PoiListView: View {
    let pois: [PointOfInterest]

    var body: some View {
        ForEach(pois) { poi in
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
        }
    }
}
