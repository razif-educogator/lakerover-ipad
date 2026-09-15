import Foundation
import Observation
import SwiftData

/// Keeps SwiftData in step with the rover: station statuses, sample records, mission state.
@MainActor
@Observable
final class MissionRuntime {
    private(set) var activeMission: Mission?
    /// Sample created by the run currently in progress, so the Sampling screen can show it.
    private(set) var lastSample: Sample?

    private let context: ModelContext
    private var lastStationIndex: Int?

    init(context: ModelContext) {
        self.context = context
    }

    var hasActiveMission: Bool { activeMission != nil }

    func setActive(_ mission: Mission?) {
        activeMission = mission
        lastStationIndex = nil
        if let mission, mission.startedAt == nil {
            mission.startedAt = Date()
        }
        try? context.save()
    }

    func route() -> [RouteStation] {
        (activeMission?.orderedStations ?? []).map(RouteStation.init(station:))
    }

    func station(at index: Int) -> Station? {
        activeMission?.orderedStations.first { $0.index == index }
    }

    func station(id: UUID) -> Station? {
        let all = (try? context.fetch(FetchDescriptor<Station>())) ?? []
        return all.first { $0.id == id }
    }

    // MARK: Telemetry → persistence

    func ingest(_ telemetry: Telemetry) {
        guard let mission = activeMission else { return }

        if let index = telemetry.sampling?.stationIndex,
           let station = station(at: index),
           station.status == .waiting {
            station.status = .inProgress
        }

        if let index = telemetry.currentStationIndex, index != lastStationIndex {
            lastStationIndex = index
        }

        if let completion = telemetry.completedSampling {
            record(completion, in: mission)
        }

        if telemetry.missionCompleted, mission.state != .completed {
            mission.state = .completed
            mission.completedAt = Date()
            try? context.save()
        } else if telemetry.isPaused, mission.state == .active {
            mission.state = .paused
        } else if !telemetry.isPaused, mission.state == .paused {
            mission.state = .active
        }
    }

    private func record(_ completion: CompletedSampling, in mission: Mission) {
        guard let station = station(at: completion.stationIndex) else { return }
        let sample = Sample(
            code: nextSampleCode(in: mission),
            takenAt: completion.takenAt,
            latitude: completion.latitude,
            longitude: completion.longitude,
            volumeL: completion.volumeL,
            targetVolumeL: completion.targetVolumeL,
            tagID: completion.cartridgeID,
            status: completion.cancelled ? .cancelled : .done
        )
        sample.turbidityNTU = completion.turbidityNTU
        sample.temperatureC = completion.temperatureC
        sample.pH = completion.pH
        sample.dissolvedOxygenMgL = completion.dissolvedOxygenMgL
        attachMicroparticles(
            to: sample,
            station: station,
            jarID: completion.mpfJarID,
            filteredL: completion.filteredVolumeL,
            collected: !completion.cancelled
        )
        sample.station = station
        sample.mission = mission
        context.insert(sample)

        station.status = completion.cancelled ? .waiting : .done
        station.completedAt = completion.cancelled ? nil : completion.takenAt
        if !completion.cancelled {
            station.lastSampleAt = completion.takenAt
            station.lastTurbidityNTU = completion.turbidityNTU
        }
        lastSample = sample
        try? context.save()
    }

    /// Phase one of Mikropartikel: the field half. The jar exists and goes off to the lab;
    /// the numbers only appear if this station's script says the lab already reported.
    private func attachMicroparticles(
        to sample: Sample,
        station: Station,
        jarID: String,
        filteredL: Double,
        collected: Bool
    ) {
        guard collected, station.targetParameters.contains(.microparticles) else {
            sample.labStatus = .notCollected
            return
        }
        sample.mpfJarID = jarID
        sample.filteredVolumeL = filteredL
        sample.labStatus = station.plannedLabStatus
        if station.plannedLabStatus.hasResult {
            sample.microplasticsPerL = station.plannedMicroplasticsPerL
            sample.microfibrePerL = station.plannedMicrofibrePerL
        }
    }

    private func nextSampleCode(in mission: Mission) -> String {
        let year = Calendar.current.component(.year, from: Date())
        return String(format: "LR-%d-%03d", year, mission.samples.count + 1)
    }

    // MARK: Demo helpers

    /// Marks the stations before `index` as done with scripted readings, so the Showcase run
    /// can jump straight to a station without waiting for the whole route.
    func fastForward(to index: Int) {
        guard let mission = activeMission else { return }
        for station in mission.orderedStations where station.index < index && station.status != .done {
            addScriptedSample(for: station, in: mission, minutesAgo: Double(index - station.index) * 2)
        }
        try? context.save()
    }

    /// Gives Insights a full set of stations to draw, however far the live run got.
    func fillDemoSamples() {
        guard let mission = activeMission else { return }
        for station in mission.orderedStations where station.status != .done {
            addScriptedSample(for: station, in: mission, minutesAgo: Double(mission.stations.count - station.index))
        }
        try? context.save()
    }

    private func addScriptedSample(for station: Station, in mission: Mission, minutesAgo: Double) {
        let base = (station.lastTurbidityNTU ?? 12) * 1.15
        let i = Double(station.index)
        let sample = Sample(
            code: nextSampleCode(in: mission),
            takenAt: Date().addingTimeInterval(-minutesAgo * 60),
            latitude: station.latitude,
            longitude: station.longitude,
            volumeL: 5,
            targetVolumeL: 5,
            tagID: String(format: "C%02d-A91", station.index + 1),
            status: .done
        )
        sample.turbidityNTU = base
        sample.temperatureC = 28.0 + 0.15 * i
        sample.pH = 7.5 - 0.09 * i
        sample.dissolvedOxygenMgL = 7.4 - 0.22 * i
        attachMicroparticles(
            to: sample,
            station: station,
            jarID: station.mpfJarID ?? String(format: "J%02d-M07", station.index + 1),
            filteredL: 5,
            collected: true
        )
        sample.station = station
        sample.mission = mission
        context.insert(sample)

        station.status = .done
        station.completedAt = sample.takenAt
    }

    /// The completed mission on the same lake, used as the Insights comparison line.
    func previousMission(for mission: Mission) -> Mission? {
        let all = (try? context.fetch(FetchDescriptor<Mission>())) ?? []
        return all
            .filter { $0.id != mission.id && $0.lakeName == mission.lakeName && !$0.samples.isEmpty }
            .sorted { $0.plannedDate > $1.plannedDate }
            .first
    }
}
