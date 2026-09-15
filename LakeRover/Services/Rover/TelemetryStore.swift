import Foundation
import Observation

/// Latest rover state plus the short history the charts need. Every screen reads this.
@MainActor
@Observable
final class TelemetryStore {
    struct SolarSample: Identifiable, Sendable {
        var id: Int
        var minute: Int
        var watts: Double
    }

    private(set) var latest = Telemetry()
    private(set) var hasData = false
    /// One frame per second, capped at 30 minutes.
    private(set) var history: [Telemetry] = []
    /// One bucket per simulated minute of the session.
    private(set) var solarHistory: [SolarSample] = []

    private var lastHistoryUptime: Double = -1
    private var solarBucketTotals: [Int: (sum: Double, count: Int)] = [:]

    func ingest(_ telemetry: Telemetry) {
        latest = telemetry
        hasData = true

        if telemetry.uptime - lastHistoryUptime >= 1 {
            lastHistoryUptime = telemetry.uptime
            history.append(telemetry)
            if history.count > 1800 { history.removeFirst(history.count - 1800) }
        }

        let minute = Int(telemetry.uptime / 60)
        var bucket = solarBucketTotals[minute] ?? (0, 0)
        bucket.sum += telemetry.solarW
        bucket.count += 1
        solarBucketTotals[minute] = bucket
        rebuildSolarHistory()
    }

    func reset() {
        latest = Telemetry()
        hasData = false
        history = []
        solarHistory = []
        solarBucketTotals = [:]
        lastHistoryUptime = -1
    }

    private func rebuildSolarHistory() {
        solarHistory = solarBucketTotals
            .sorted { $0.key < $1.key }
            .suffix(12)
            .map { SolarSample(id: $0.key, minute: $0.key, watts: $0.value.sum / Double(max($0.value.count, 1))) }
    }

    // MARK: Derived

    /// Average watt draw over the last two minutes of history.
    var averageDrawW: Double {
        let recent = history.suffix(120)
        guard !recent.isEmpty else { return max(latest.powerBreakdown.totalW, 8) }
        let total = recent.reduce(0.0) { $0 + $1.powerBreakdown.totalW }
        return max(total / Double(recent.count), 4)
    }

    /// Rough remaining runtime, from a 240 Wh pack minus the solar contribution.
    var estimatedRuntime: TimeInterval {
        let packWh: Double = 240
        let remainingWh = packWh * Double(latest.batteryPct) / 100
        let net = max(averageDrawW - latest.solarW * 0.35, 2)
        return remainingWh / net * 3600
    }

    var runtimeText: String {
        let seconds = Int(estimatedRuntime)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours) jam \(minutes) min" : "\(minutes) min"
    }

    func values(of parameter: Parameter) -> [Double] {
        history.compactMap { $0.sampling?.value(for: parameter) }
    }
}
