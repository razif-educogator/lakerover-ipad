import CoreLocation
import Foundation

struct SamplingTelemetry: Sendable, Equatable {
    var stationIndex: Int
    var phase: SamplingPhase
    var elapsed: TimeInterval
    var pumpFlowLpm: Double
    var filledL: Double
    var targetL: Double
    var turbidityNTU: Double
    var temperatureC: Double
    var pH: Double
    var dissolvedOxygenMgL: Double
    var cartridgeID: String
    var estimatedSecondsRemaining: Double
    /// Mikropartikel: the jar being filled alongside the sensor readings.
    var mpfJarID: String = ""
    var mpfFilteredL: Double = 0
    var mpfTargetL: Double = 5
    /// The jar tag is only read once the Tag step is reached.
    var mpfJarTagged: Bool = false

    /// Field sensors only. Mikropartikel has no live value by definition.
    func value(for parameter: Parameter) -> Double {
        switch parameter {
        case .turbidity: turbidityNTU
        case .temperature: temperatureC
        case .pH: pH
        case .dissolvedOxygen: dissolvedOxygenMgL
        case .conductivity, .microparticles: 0
        }
    }
}

struct PowerBreakdown: Sendable, Equatable {
    var thrusterW: Double = 0
    var pumpW: Double = 0
    var linkW: Double = 0
    var computeW: Double = 0
    var sensorsW: Double = 0

    var totalW: Double { thrusterW + pumpW + linkW + computeW + sensorsW }

    var rows: [(label: LocalizedStringResource, watts: Double)] {
        [
            ("Motor pendorong", thrusterW),
            ("Pam pensampelan", pumpW),
            ("Komunikasi 4G", linkW),
            ("Sistem komputer", computeW),
            ("Kamera & sensor", sensorsW)
        ]
    }
}

/// Emitted on exactly one frame, when a station's sampling run ends.
struct CompletedSampling: Sendable, Equatable {
    var stationIndex: Int
    var cancelled: Bool
    var takenAt: Date
    var latitude: Double
    var longitude: Double
    var volumeL: Double
    var targetVolumeL: Double
    var turbidityNTU: Double
    var temperatureC: Double
    var pH: Double
    var dissolvedOxygenMgL: Double
    var cartridgeID: String
    /// Mikropartikel jar handed off to the lab. Results arrive separately.
    var mpfJarID: String
    var filteredVolumeL: Double
}

/// One frame of rover state. Everything the UI shows comes from here.
struct Telemetry: Sendable, Equatable {
    var timestamp: Date = Date()
    /// Seconds of *mission* time since start. Alert rules measure durations with this so
    /// they still fire when the demo runs at 5×.
    var uptime: TimeInterval = 0
    var latitude: Double = 0
    var longitude: Double = 0
    var headingDeg: Double = 0
    var speedMps: Double = 0
    var batteryPct: Int = 100
    var batteryRatePctPerMin: Double = 0
    var solarW: Double = 0
    var linkQuality: Int = 4
    var linkType: String = "4G"
    var gpsSatellites: Int = 9
    var sampling: SamplingTelemetry?
    var powerBreakdown = PowerBreakdown()
    var obstacleDetected = false
    var waterIngress = false
    var currentStationIndex: Int?
    var etaToStationS: Double?
    var distanceToStationM: Double?
    var isMoving = false
    var isPaused = false
    var isStopped = false
    var missionCompleted = false
    var completedSampling: CompletedSampling?
    /// The rover is retracing the mission route back to the jetty.
    var isReturning = false
    /// Station the retrace started from; the return leg runs from here back to station 0,
    /// so the map can draw it without guessing.
    var returnFromStationIndex: Int?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// "245° SW"
    var headingText: String {
        let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let idx = Int((headingDeg / 45).rounded()) % 8
        return "\(Int(headingDeg.rounded()))° \(points[idx])"
    }
}
