import Foundation

enum RoverCommand: Sendable, Equatable {
    case loadRoute([RouteStation])
    case start
    case pause
    case resume
    case emergencyStop
    case resumeAfterStop
    case returnHome
    case skipStation(Int)
    case startSampling(stationIndex: Int, parameters: [Parameter])
    case stopSampling
    case restartSampling
    case setAutoReturn(enabled: Bool, thresholdPct: Int)
    case setAutonomous(Bool)
    case setPowerSave(Bool)
    /// Demo-only: jump the simulation straight to a station so the Showcase run stays short.
    case demoSkipTo(stationIndex: Int)
}

/// A station reduced to the values the rover link needs — keeps SwiftData out of the client.
struct RouteStation: Sendable, Equatable, Identifiable {
    var id: UUID
    var index: Int
    var name: String
    var zone: String
    var latitude: Double
    var longitude: Double
    var depthM: Double
    var baseTurbidityNTU: Double
    var baseTemperatureC: Double
    var basePH: Double
    var baseDOMgL: Double
    var cartridgeID: String
    var mpfJarID: String
}

extension RouteStation {
    init(station: Station) {
        self.init(
            id: station.id,
            index: station.index,
            name: station.name,
            zone: station.zone,
            latitude: station.latitude,
            longitude: station.longitude,
            depthM: station.depthM ?? 3,
            baseTurbidityNTU: station.lastTurbidityNTU ?? 12,
            baseTemperatureC: 28.4,
            basePH: 7.2,
            baseDOMgL: 6.8,
            cartridgeID: String(format: "C%02d-A91", station.index + 1),
            mpfJarID: station.mpfJarID ?? String(format: "J%02d-M07", station.index + 1)
        )
    }
}

enum RoverError: LocalizedError {
    case notAvailable
    case timeout

    var errorDescription: String? {
        switch self {
        case .notAvailable: "Pautan rover tidak tersedia."
        case .timeout: "Arahan gagal dihantar, cuba lagi."
        }
    }
}
