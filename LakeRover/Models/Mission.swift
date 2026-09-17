import Foundation
import SwiftData

@Model
final class Mission {
    var id: UUID = UUID()
    var name: String = ""
    var lakeName: String = ""
    var plannedDate: Date = Date()
    var state: MissionState = MissionState.planned
    var routeLengthM: Double = 0
    var turbidityThresholdNTU: Double = 15
    /// Rover unit assigned to this lake, e.g. "LakeRover-02". `nil` falls back to the unit
    /// named in `AppSettings`.
    var roverName: String?
    /// Set when the mission actually starts, used by Insights for "Misi ini".
    var startedAt: Date?
    var completedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Station.mission)
    var stations: [Station] = []

    @Relationship(deleteRule: .cascade, inverse: \Sample.mission)
    var samples: [Sample] = []

    init(
        id: UUID = UUID(),
        name: String,
        lakeName: String,
        plannedDate: Date,
        state: MissionState = .planned,
        routeLengthM: Double = 0,
        turbidityThresholdNTU: Double = 15
    ) {
        self.id = id
        self.name = name
        self.lakeName = lakeName
        self.plannedDate = plannedDate
        self.state = state
        self.routeLengthM = routeLengthM
        self.turbidityThresholdNTU = turbidityThresholdNTU
    }

    var orderedStations: [Station] {
        stations.sorted { $0.index < $1.index }
    }

    var orderedSamples: [Sample] {
        samples.sorted { $0.takenAt < $1.takenAt }
    }

    var completedStationCount: Int {
        stations.count { $0.status == .done }
    }

    var progressFraction: Double {
        guard !stations.isEmpty else { return 0 }
        return Double(completedStationCount) / Double(stations.count)
    }
}
