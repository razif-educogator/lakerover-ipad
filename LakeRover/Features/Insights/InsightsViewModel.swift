import Foundation
import Observation

enum InsightsRange: String, CaseIterable {
    case mission, days30

    var label: String {
        switch self {
        case .mission: String(localized: "Misi ini")
        case .days30: String(localized: "30 hari")
        }
    }
}

struct StationPoint: Identifiable, Equatable {
    var id: Int
    var code: String
    var name: String
    var value: Double
    var latitude: Double
    var longitude: Double
}

/// Statistics for the Data & insight screen. Pure functions over samples — no SwiftUI.
@MainActor
@Observable
final class InsightsViewModel {
    var parameter: Parameter = .turbidity
    var range: InsightsRange = .mission

    // MARK: Series

    func series(for mission: Mission?) -> [StationPoint] {
        guard let mission else { return [] }
        let samples = range == .mission
            ? mission.orderedSamples
            : mission.orderedSamples + recent(from: mission)
        return points(from: samples, stations: mission.orderedStations)
    }

    func comparisonSeries(previous: Mission?) -> [StationPoint] {
        guard let previous else { return [] }
        return points(from: previous.orderedSamples, stations: previous.orderedStations)
    }

    private func recent(from mission: Mission) -> [Sample] {
        let cutoff = Date().addingTimeInterval(-30 * 86_400)
        return mission.orderedSamples.filter { $0.takenAt >= cutoff }
    }

    private func points(from samples: [Sample], stations: [Station]) -> [StationPoint] {
        stations.compactMap { station in
            let values = samples
                .filter { $0.station?.id == station.id && $0.status == .done }
                .compactMap { $0.value(for: parameter) }
            guard !values.isEmpty else { return nil }
            return StationPoint(
                id: station.index,
                code: station.shortCode,
                name: station.name,
                value: values.reduce(0, +) / Double(values.count),
                latitude: station.latitude,
                longitude: station.longitude
            )
        }
    }

    // MARK: Statistics

    func average(_ points: [StationPoint]) -> Double? {
        guard !points.isEmpty else { return nil }
        return points.reduce(0) { $0 + $1.value } / Double(points.count)
    }

    func change(current: [StationPoint], previous: [StationPoint]) -> Double? {
        guard let a = average(current), let b = average(previous) else { return nil }
        return a - b
    }

    func highest(_ points: [StationPoint]) -> StationPoint? {
        points.max { $0.value < $1.value }
    }

    /// R9.4 — stations over the mission's turbidity threshold.
    func exceeding(_ points: [StationPoint], threshold: Double) -> [StationPoint] {
        guard parameter == .turbidity else { return [] }
        return points.filter { $0.value > threshold }
    }

    func recommendation(for exceeded: [StationPoint], threshold: Double) -> String? {
        guard let worst = exceeded.max(by: { $0.value < $1.value }) else { return nil }
        return String(
            format: "Semak sumber sedimen berhampiran %@ (%@). Ulang sampel minggu depan dan bandingkan dengan had %.0f NTU.",
            worst.name, worst.code, threshold
        )
    }

    func attentionText(for exceeded: [StationPoint], threshold: Double) -> String? {
        guard let worst = exceeded.max(by: { $0.value < $1.value }) else { return nil }
        return String(format: "%@ (%@) — %.1f NTU, melebihi had %.0f NTU.", worst.name, worst.code, worst.value, threshold)
    }
}
