import MapKit
import SwiftUI

/// Non-interactive map used in Station Detail and the PDF report.
struct MiniMap: View {
    var stations: [Station]
    var highlighted: Station?
    var height: CGFloat = 150

    var body: some View {
        Map(initialPosition: .region(region), interactionModes: []) {
            if stations.count > 1 {
                MapPolyline(coordinates: stations.map(\.coordinate))
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))
            }
            ForEach(stations) { station in
                Annotation(station.shortCode, coordinate: station.coordinate) {
                    StationAnnotationView(station: station, isCurrent: station.id == highlighted?.id)
                        .scaleEffect(station.id == highlighted?.id ? 1 : 0.8)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .allowsHitTesting(false)
    }

    private var region: MKCoordinateRegion {
        let coordinates = stations.map(\.coordinate)
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 5.0112, longitude: 100.9714),
                latitudinalMeters: 600,
                longitudinalMeters: 600
            )
        }
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: ((lats.min() ?? first.latitude) + (lats.max() ?? first.latitude)) / 2,
            longitude: ((lons.min() ?? first.longitude) + (lons.max() ?? first.longitude)) / 2
        )
        let spanLat = max((lats.max() ?? 0) - (lats.min() ?? 0), 0.002) * 1.6
        let spanLon = max((lons.max() ?? 0) - (lons.min() ?? 0), 0.002) * 1.6
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        )
    }
}
