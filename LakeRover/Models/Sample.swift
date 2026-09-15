import CoreLocation
import Foundation
import SwiftData

@Model
final class Sample {
    var id: UUID = UUID()
    var code: String = ""
    var takenAt: Date = Date()
    var latitude: Double = 0
    var longitude: Double = 0
    var volumeL: Double = 0
    var targetVolumeL: Double = 5
    var tagID: String?
    var status: SampleStatus = SampleStatus.waiting
    var turbidityNTU: Double?
    var temperatureC: Double?
    var pH: Double?
    var dissolvedOxygenMgL: Double?
    var studentNote: String = ""

    var station: Station?
    var mission: Mission?

    init(
        id: UUID = UUID(),
        code: String,
        takenAt: Date,
        latitude: Double,
        longitude: Double,
        volumeL: Double = 0,
        targetVolumeL: Double = 5,
        tagID: String? = nil,
        status: SampleStatus = .waiting
    ) {
        self.id = id
        self.code = code
        self.takenAt = takenAt
        self.latitude = latitude
        self.longitude = longitude
        self.volumeL = volumeL
        self.targetVolumeL = targetVolumeL
        self.tagID = tagID
        self.status = status
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func value(for parameter: Parameter) -> Double? {
        switch parameter {
        case .turbidity: turbidityNTU
        case .temperature: temperatureC
        case .pH: pH
        case .dissolvedOxygen: dissolvedOxygenMgL
        case .conductivity: nil
        }
    }
}
