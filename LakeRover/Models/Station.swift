import CoreLocation
import Foundation
import SwiftData

@Model
final class Station {
    var id: UUID = UUID()
    var index: Int = 0
    var name: String = ""
    var zone: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var depthM: Double?
    var targetParameters: [Parameter] = []
    var status: StationStatus = StationStatus.waiting
    var completedAt: Date?
    /// Readings from the previous mission, shown in Station Detail before sampling.
    var lastSampleAt: Date?
    var lastTurbidityNTU: Double?

    var mission: Mission?

    @Relationship(deleteRule: .nullify, inverse: \Sample.station)
    var samples: [Sample] = []

    init(
        id: UUID = UUID(),
        index: Int,
        name: String,
        zone: String,
        latitude: Double,
        longitude: Double,
        depthM: Double? = nil,
        targetParameters: [Parameter] = [.turbidity, .temperature, .pH, .dissolvedOxygen],
        status: StationStatus = .waiting
    ) {
        self.id = id
        self.index = index
        self.name = name
        self.zone = zone
        self.latitude = latitude
        self.longitude = longitude
        self.depthM = depthM
        self.targetParameters = targetParameters
        self.status = status
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// "S4" — the label used on map pins, timelines and charts.
    var shortCode: String { "S\(index + 1)" }
}
