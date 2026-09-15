import SwiftUI

/// Lake heat map: an 8 × 6 grid coloured by inverse-distance weighting of the station
/// readings, so the shape of the problem is visible at a glance (R9.2).
struct HeatMapGrid: View {
    var points: [StationPoint]
    var columns = 8
    var rows = 6

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<columns, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(color(row: row, column: column))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .accessibilityLabel("Peta haba tasik")
    }

    private var bounds: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double)? {
        guard !points.isEmpty else { return nil }
        let lats = points.map(\.latitude)
        let lons = points.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max()
        else { return nil }
        let padLat = max((maxLat - minLat) * 0.25, 0.0004)
        let padLon = max((maxLon - minLon) * 0.25, 0.0004)
        return (minLat - padLat, maxLat + padLat, minLon - padLon, maxLon + padLon)
    }

    private var valueRange: (low: Double, high: Double) {
        let values = points.map(\.value)
        let low = values.min() ?? 0
        let high = values.max() ?? 1
        return high - low < 0.001 ? (low - 1, high + 1) : (low, high)
    }

    private func color(row: Int, column: Int) -> Color {
        guard let bounds else { return Color(.tertiarySystemFill) }
        let lon = bounds.minLon + (bounds.maxLon - bounds.minLon) * (Double(column) + 0.5) / Double(columns)
        let lat = bounds.maxLat - (bounds.maxLat - bounds.minLat) * (Double(row) + 0.5) / Double(rows)

        var weightedSum = 0.0
        var weights = 0.0
        for point in points {
            let dLat = (point.latitude - lat) * 111_132
            let dLon = (point.longitude - lon) * 110_900
            let distance = max((dLat * dLat + dLon * dLon).squareRoot(), 4)
            let weight = 1 / (distance * distance)
            weightedSum += point.value * weight
            weights += weight
        }
        guard weights > 0 else { return Color(.tertiarySystemFill) }

        let value = weightedSum / weights
        let range = valueRange
        let t = min(max((value - range.low) / (range.high - range.low), 0), 1)
        return Theme.accent.opacity(0.12 + 0.78 * t)
    }
}
