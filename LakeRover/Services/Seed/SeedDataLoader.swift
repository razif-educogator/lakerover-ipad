import Foundation
import SwiftData

/// Fills an empty store with the three demo missions and one completed prior mission
/// so Insights has something to compare against. Runs once, on first launch.
@MainActor
enum SeedDataLoader {
    static let demoLakeName = "Tasik Cenderoh"

    static func loadIfNeeded(into context: ModelContext) {
        ensureSettings(in: context)

        let existing = try? context.fetch(FetchDescriptor<Mission>())
        guard (existing?.isEmpty ?? true) else { return }

        insert(fileNamed: "history", into: context)
        insert(fileNamed: "missions", into: context)
        try? context.save()
    }

    static func settings(in context: ModelContext) -> AppSettings {
        ensureSettings(in: context)
        return (try? context.fetch(FetchDescriptor<AppSettings>()))?.first ?? AppSettings()
    }

    /// The mission the demo and Showcase modes always run.
    static func demoMission(in context: ModelContext) -> Mission? {
        let missions = (try? context.fetch(FetchDescriptor<Mission>())) ?? []
        return missions.first { $0.lakeName == demoLakeName && $0.state != .completed }
    }

    // MARK: - Private

    private static func ensureSettings(in context: ModelContext) {
        let rows = (try? context.fetch(FetchDescriptor<AppSettings>())) ?? []
        if rows.isEmpty {
            context.insert(AppSettings())
            try? context.save()
        }
    }

    private static func insert(fileNamed name: String, into context: ModelContext) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(SeedFile.self, from: data)
        else { return }

        for dto in file.missions {
            context.insert(mission(from: dto))
        }
    }

    private static func mission(from dto: SeedMission) -> Mission {
        let date = Calendar.current.date(byAdding: .day, value: dto.dayOffset, to: Date()) ?? Date()
        let mission = Mission(
            name: dto.name,
            lakeName: dto.lakeName,
            plannedDate: date,
            state: MissionState(rawValue: dto.state) ?? .planned,
            routeLengthM: dto.routeLengthM,
            turbidityThresholdNTU: dto.turbidityThresholdNTU
        )
        if mission.state == .completed {
            mission.startedAt = date
            mission.completedAt = date
        }

        var stations: [Station] = []
        if let list = dto.stations {
            stations = list.map { s in
                let station = Station(
                    index: s.index,
                    name: s.name,
                    zone: s.zone,
                    latitude: s.latitude,
                    longitude: s.longitude,
                    depthM: s.depthM
                )
                station.lastTurbidityNTU = s.lastTurbidityNTU
                if let offset = s.lastDayOffset {
                    station.lastSampleAt = Calendar.current.date(byAdding: .day, value: offset, to: Date())
                }
                station.mpfJarID = s.mpfJarID
                station.plannedLabStatus = s.labStatus.flatMap(LabStatus.init(rawValue:)) ?? .awaiting
                station.plannedMicroplasticsPerL = s.microplasticsPerL
                station.plannedMicrofibrePerL = s.microfibrePerL
                if mission.state == .completed { station.status = .done }
                return station
            }
        } else if let auto = dto.autoStations {
            stations = autoStations(auto)
        }
        mission.stations = stations

        if let sampleDTOs = dto.samples {
            let year = Calendar.current.component(.year, from: date)
            mission.samples = sampleDTOs.enumerated().compactMap { offset, s in
                guard let station = stations.first(where: { $0.index == s.stationIndex }) else { return nil }
                let takenAt = date.addingTimeInterval(Double(s.minuteOffset) * 60)
                let sample = Sample(
                    code: String(format: "LR-%d-%03d", year, offset + 1),
                    takenAt: takenAt,
                    latitude: station.latitude,
                    longitude: station.longitude,
                    volumeL: 5.0,
                    tagID: s.tagID,
                    status: .done
                )
                sample.turbidityNTU = s.turbidityNTU
                sample.temperatureC = s.temperatureC
                sample.pH = s.pH
                sample.dissolvedOxygenMgL = s.dissolvedOxygenMgL
                sample.mpfJarID = s.mpfJarID
                sample.filteredVolumeL = s.filteredVolumeL
                sample.labStatus = s.labStatus.flatMap(LabStatus.init(rawValue:)) ?? .notCollected
                sample.microplasticsPerL = s.microplasticsPerL
                sample.microfibrePerL = s.microfibrePerL
                sample.station = station
                station.completedAt = takenAt
                return sample
            }
        }
        return mission
    }

    private static func autoStations(_ auto: SeedAutoStations) -> [Station] {
        (0..<auto.count).map { i in
            let angle = 2 * Double.pi * Double(i) / Double(auto.count)
            let dLat = (auto.radiusM / 111_000) * cos(angle)
            let dLon = (auto.radiusM / (111_000 * cos(auto.latitude * .pi / 180))) * sin(angle)
            return Station(
                index: i,
                name: "Stesen \(i + 1)",
                zone: "Zon \(i + 1)",
                latitude: auto.latitude + dLat,
                longitude: auto.longitude + dLon,
                depthM: 3.0 + Double(i % 3)
            )
        }
    }
}

// MARK: - Seed DTOs

private struct SeedFile: Decodable {
    var missions: [SeedMission]
}

private struct SeedMission: Decodable {
    var name: String
    var lakeName: String
    var dayOffset: Int
    var state: String
    var routeLengthM: Double
    var turbidityThresholdNTU: Double
    var stations: [SeedStation]?
    var autoStations: SeedAutoStations?
    var samples: [SeedSample]?
}

private struct SeedStation: Decodable {
    var index: Int
    var name: String
    var zone: String
    var latitude: Double
    var longitude: Double
    var depthM: Double?
    var lastTurbidityNTU: Double?
    var lastDayOffset: Int?
    // Mikropartikel script for the live demo run.
    var mpfJarID: String?
    var labStatus: String?
    var microplasticsPerL: Double?
    var microfibrePerL: Double?
}

private struct SeedAutoStations: Decodable {
    var count: Int
    var latitude: Double
    var longitude: Double
    var radiusM: Double
}

private struct SeedSample: Decodable {
    var stationIndex: Int
    var minuteOffset: Int
    var turbidityNTU: Double
    var temperatureC: Double
    var pH: Double
    var dissolvedOxygenMgL: Double
    var tagID: String
    // Mikropartikel: jar plus the lab result, if one came back.
    var mpfJarID: String?
    var filteredVolumeL: Double?
    var labStatus: String?
    var microplasticsPerL: Double?
    var microfibrePerL: Double?
}
