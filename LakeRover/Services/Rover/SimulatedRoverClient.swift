import CoreLocation
import Foundation

/// Plays a scripted mission on Tasik Cenderoh: travel at 1.2 m/s, a 45 s sampling run at
/// every station, a battery that reaches 20 % before station 5, an obstacle on the way to
/// station 3 and a blocked pump at station 4. Deterministic for a given seed.
@MainActor
final class SimulatedRoverClient: RoverClient {
    let isDemo = true
    var speedMultiplier: Double = 1

    // MARK: Script constants

    private let cruiseSpeed: Double = 1.2
    private let tickInterval: Double = 0.15
    private let phaseDurations: [SamplingPhase: Double] = [
        .arrive: 3, .register: 4, .sample: 22, .tag: 6, .store: 5, .move: 5
    ]
    private let obstacleLeg = 2          // travelling towards S3
    private let lowFlowStation = 3       // S4
    private let targetVolume: Double = 5.0

    // MARK: State

    private enum Mode { case idle, travelling, sampling, paused, stopped, returning, completed }

    private var route: [RouteStation] = []
    private var continuation: AsyncStream<Telemetry>.Continuation?
    private var ticker: Task<Void, Never>?

    private var mode: Mode = .idle
    private var resumeMode: Mode = .travelling
    private var targetIndex = 0
    private var legProgress: Double = 0        // metres travelled on the current leg
    private var samplingElapsed: Double = 0
    private var samplingCancelled = false
    private var skipped: Set<Int> = []
    private var uptime: Double = 0
    private var battery: Double = 78
    private var batteryRate: Double = 0
    private var position = CLLocationCoordinate2D()
    private var heading: Double = 0
    private var rng = SeededGenerator()
    private var pendingCompletion: CompletedSampling?
    private var readings = (turbidity: 0.0, temperature: 0.0, pH: 0.0, dissolvedOxygen: 0.0)

    // MARK: RoverClient

    func connect() async throws {
        // The simulator is always reachable.
    }

    func telemetry() -> AsyncStream<Telemetry> {
        AsyncStream(bufferingPolicy: .unbounded) { continuation in
            self.continuation = continuation
        }
    }

    func send(_ command: RoverCommand) async throws {
        switch command {
        case .loadRoute(let stations):
            route = stations.sorted { $0.index < $1.index }
            position = route.first?.coordinate ?? position
            targetIndex = 0
            legProgress = 0
            uptime = 0
            battery = 78
            skipped = []
            mode = .idle
            emit()

        case .start:
            guard !route.isEmpty else { return }
            targetIndex = 0
            beginSampling(at: 0)
            startTicker()

        case .pause:
            if mode != .paused { resumeMode = mode; mode = .paused }

        case .resume:
            if mode == .paused { mode = resumeMode }

        case .emergencyStop:
            if mode != .stopped { resumeMode = mode; mode = .stopped }

        case .resumeAfterStop:
            if mode == .stopped { mode = resumeMode }

        case .returnHome:
            mode = .returning
            legProgress = 0

        case .skipStation(let index):
            skipped.insert(index)
            if targetIndex == index { advancePastStation() }

        case .startSampling(let index, _):
            beginSampling(at: index)

        case .stopSampling:
            if mode == .sampling {
                samplingCancelled = true
                finishSampling()
            }

        case .restartSampling:
            samplingCancelled = false
            samplingElapsed = elapsedAtStart(of: .sample)
            readings = (0, 0, 0, 0)

        case .demoSkipTo(let index):
            guard route.indices.contains(index) else { return }
            for i in 0..<index { skipped.remove(i) }
            targetIndex = index
            position = route[index].coordinate
            legProgress = 0
            uptime = max(uptime, Double(index) * 95)
            battery = batteryLevel(forProgress: Double(index) / Double(max(route.count, 1)))
            beginSampling(at: index)
            startTicker()

        case .setAutoReturn, .setAutonomous, .setPowerSave:
            break
        }
        emit()
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        continuation?.finish()
        continuation = nil
    }

    // MARK: Loop

    private func startTicker() {
        guard ticker == nil else { return }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.15))
                guard let self else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        let dt = tickInterval * speedMultiplier
        switch mode {
        case .idle, .paused, .stopped, .completed:
            batteryRate = mode == .completed ? 0 : -0.05
            uptime += dt
        case .travelling:
            uptime += dt
            advanceTravel(dt: dt)
        case .sampling:
            uptime += dt
            advanceSampling(dt: dt)
        case .returning:
            uptime += dt
            advanceReturn(dt: dt)
        }
        updateBattery(dt: dt)
        emit()
    }

    // MARK: Travelling

    private func advanceTravel(dt: Double) {
        guard route.indices.contains(targetIndex), targetIndex > 0 else {
            beginSampling(at: targetIndex)
            return
        }
        let from = route[targetIndex - 1].coordinate
        let to = route[targetIndex].coordinate
        let legLength = max(Geo.distance(from, to), 1)

        let blocked = targetIndex == obstacleLeg && legProgress / legLength > 0.45 && legProgress / legLength < 0.72
        let speed = blocked ? 0.35 : cruiseSpeed
        legProgress = min(legProgress + speed * dt, legLength)

        let t = legProgress / legLength
        position = Geo.interpolate(from, to, fraction: t)
        heading = Geo.bearing(from: from, to: to)

        if legProgress >= legLength - 0.5 {
            if skipped.contains(targetIndex) {
                advancePastStation()
            } else {
                beginSampling(at: targetIndex)
            }
        }
    }

    private func advanceReturn(dt: Double) {
        guard let home = route.first?.coordinate else { mode = .completed; return }
        let remaining = Geo.distance(position, home)
        if remaining < 1 {
            mode = .completed
            return
        }
        heading = Geo.bearing(from: position, to: home)
        let step = min(cruiseSpeed * dt, remaining)
        position = Geo.interpolate(position, home, fraction: step / remaining)
    }

    // MARK: Sampling

    private func beginSampling(at index: Int) {
        guard route.indices.contains(index) else { return }
        targetIndex = index
        position = route[index].coordinate
        legProgress = 0
        samplingElapsed = 0
        samplingCancelled = false
        readings = (0, 0, 0, 0)
        mode = .sampling
    }

    private func advanceSampling(dt: Double) {
        samplingElapsed += dt
        let phase = currentPhase
        let station = route[targetIndex]

        // Readings settle during the Sampel step.
        let target = targets(for: station)
        if phase >= .sample {
            let progress = min(1, max(0, (samplingElapsed - elapsedAtStart(of: .sample)) / phaseDuration(.sample)))
            let ease = progress * progress * (3 - 2 * progress)
            readings.turbidity = target.turbidity * (0.55 + 0.45 * ease) + rng.noise(0.12)
            readings.temperature = target.temperature * (0.97 + 0.03 * ease) + rng.noise(0.05)
            readings.pH = target.pH * (0.96 + 0.04 * ease) + rng.noise(0.02)
            readings.dissolvedOxygen = target.dissolvedOxygen * (0.92 + 0.08 * ease) + rng.noise(0.04)
        }

        if samplingElapsed >= totalSamplingDuration {
            finishSampling()
        }
    }

    private func finishSampling() {
        let station = route[targetIndex]
        let target = targets(for: station)
        if samplingCancelled {
            pendingCompletion = CompletedSampling(
                stationIndex: targetIndex, cancelled: true, takenAt: Date(),
                latitude: station.latitude, longitude: station.longitude,
                volumeL: filledVolume, targetVolumeL: targetVolume,
                turbidityNTU: readings.turbidity, temperatureC: readings.temperature,
                pH: readings.pH, dissolvedOxygenMgL: readings.dissolvedOxygen,
                cartridgeID: station.cartridgeID,
                mpfJarID: station.mpfJarID, filteredVolumeL: filledVolume
            )
        } else {
            pendingCompletion = CompletedSampling(
                stationIndex: targetIndex, cancelled: false, takenAt: Date(),
                latitude: station.latitude, longitude: station.longitude,
                volumeL: targetVolume, targetVolumeL: targetVolume,
                turbidityNTU: target.turbidity, temperatureC: target.temperature,
                pH: target.pH, dissolvedOxygenMgL: target.dissolvedOxygen,
                cartridgeID: station.cartridgeID,
                mpfJarID: station.mpfJarID, filteredVolumeL: targetVolume
            )
        }
        advancePastStation()
    }

    private func advancePastStation() {
        let next = targetIndex + 1
        if route.indices.contains(next) {
            targetIndex = next
            legProgress = 0
            mode = .travelling
        } else {
            mode = .completed
        }
    }

    private var currentPhase: SamplingPhase {
        var accumulated: Double = 0
        for phase in SamplingPhase.allCases {
            accumulated += phaseDuration(phase)
            if samplingElapsed < accumulated { return phase }
        }
        return .move
    }

    private func phaseDuration(_ phase: SamplingPhase) -> Double {
        phaseDurations[phase] ?? 5
    }

    private func elapsedAtStart(of phase: SamplingPhase) -> Double {
        SamplingPhase.allCases.filter { $0 < phase }.reduce(0) { $0 + phaseDuration($1) }
    }

    private var totalSamplingDuration: Double {
        SamplingPhase.allCases.reduce(0) { $0 + phaseDuration($1) }
    }

    private var filledVolume: Double {
        guard currentPhase >= .sample else { return 0 }
        let progress = min(1, max(0, (samplingElapsed - elapsedAtStart(of: .sample)) / phaseDuration(.sample)))
        return targetVolume * progress
    }

    private func targets(for station: RouteStation) -> (turbidity: Double, temperature: Double, pH: Double, dissolvedOxygen: Double) {
        let i = Double(station.index)
        return (
            turbidity: station.baseTurbidityNTU * 1.15,
            temperature: 28.0 + 0.15 * i,
            pH: 7.5 - 0.09 * i,
            dissolvedOxygen: 7.4 - 0.22 * i
        )
    }

    // MARK: Power

    private func batteryLevel(forProgress p: Double) -> Double {
        p <= 0.66 ? 78 - 88.6 * p : 19.5 - (p - 0.66) * 16.2
    }

    private var missionProgress: Double {
        guard !route.isEmpty else { return 0 }
        let intra: Double
        switch mode {
        case .sampling: intra = samplingElapsed / totalSamplingDuration
        case .travelling: intra = 0
        default: intra = 0
        }
        return min(1, (Double(targetIndex) + intra) / Double(route.count))
    }

    private func updateBattery(dt: Double) {
        let next = max(6, batteryLevel(forProgress: missionProgress))
        let delta = next - battery
        battery = next
        guard dt > 0 else { return }
        let instantaneous = delta / dt * 60
        batteryRate = batteryRate * 0.85 + instantaneous * 0.15
    }

    private var solarOutput: Double {
        30 + 8 * sin(uptime / 40) + rng.noise(1.5)
    }

    private var powerBreakdown: PowerBreakdown {
        switch mode {
        case .travelling, .returning:
            PowerBreakdown(thrusterW: 5, pumpW: 0, linkW: 3, computeW: 2, sensorsW: 2)
        case .sampling:
            PowerBreakdown(thrusterW: 1, pumpW: 3, linkW: 3, computeW: 2, sensorsW: 2)
        default:
            PowerBreakdown(thrusterW: 0, pumpW: 0, linkW: 3, computeW: 2, sensorsW: 1)
        }
    }

    // MARK: Emission

    private func emit() {
        guard let continuation else { return }
        continuation.yield(makeTelemetry())
        pendingCompletion = nil
    }

    private func makeTelemetry() -> Telemetry {
        var t = Telemetry()
        t.timestamp = Date()
        t.uptime = uptime
        t.latitude = position.latitude
        t.longitude = position.longitude
        t.headingDeg = heading
        t.batteryPct = Int(battery.rounded())
        t.batteryRatePctPerMin = batteryRate
        t.solarW = max(0, solarOutput)
        t.linkQuality = mode == .idle ? 3 : 4
        t.linkType = "4G"
        t.gpsSatellites = 9
        t.powerBreakdown = powerBreakdown
        t.currentStationIndex = route.indices.contains(targetIndex) ? targetIndex : nil
        t.completedSampling = pendingCompletion
        t.isPaused = mode == .paused
        t.isStopped = mode == .stopped
        t.missionCompleted = mode == .completed

        switch mode {
        case .travelling, .returning:
            t.isMoving = true
            let blocked = mode == .travelling && targetIndex == obstacleLeg
                && legProgress / max(legLength, 1) > 0.45 && legProgress / max(legLength, 1) < 0.72
            t.obstacleDetected = blocked
            t.speedMps = blocked ? 0.35 : cruiseSpeed
        case .sampling:
            t.speedMps = 0
            t.sampling = samplingTelemetry()
        default:
            t.speedMps = 0
        }

        if route.indices.contains(targetIndex) {
            let distance = Geo.distance(position, route[targetIndex].coordinate)
            t.distanceToStationM = distance
            t.etaToStationS = t.speedMps > 0.05 ? distance / t.speedMps : (mode == .sampling ? 0 : nil)
        }
        return t
    }

    private var legLength: Double {
        guard route.indices.contains(targetIndex), targetIndex > 0 else { return 1 }
        return Geo.distance(route[targetIndex - 1].coordinate, route[targetIndex].coordinate)
    }

    private func samplingTelemetry() -> SamplingTelemetry {
        let station = route[targetIndex]
        let phase = currentPhase
        let starved = targetIndex == lowFlowStation && phase == .sample
        let flow: Double = phase == .sample ? (starved ? 0.5 : 1.2) : 0
        let sampleProgress = min(1, max(0, (samplingElapsed - elapsedAtStart(of: .sample)) / phaseDuration(.sample)))
        var telemetry = SamplingTelemetry(
            stationIndex: targetIndex,
            phase: phase,
            elapsed: samplingElapsed,
            pumpFlowLpm: flow,
            filledL: filledVolume,
            targetL: targetVolume,
            turbidityNTU: readings.turbidity,
            temperatureC: readings.temperature,
            pH: readings.pH,
            dissolvedOxygenMgL: readings.dissolvedOxygen,
            cartridgeID: station.cartridgeID,
            estimatedSecondsRemaining: max(0, (1 - sampleProgress) * phaseDuration(.sample))
        )
        // The Mikropartikel jar fills from the same pump run; its tag is read at the Tag step.
        telemetry.mpfJarID = station.mpfJarID
        telemetry.mpfFilteredL = filledVolume
        telemetry.mpfTargetL = targetVolume
        telemetry.mpfJarTagged = phase >= .tag
        return telemetry
    }
}

private extension RouteStation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
