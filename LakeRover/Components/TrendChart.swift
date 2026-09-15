import Charts
import SwiftUI

/// Parameter across stations, with the previous mission as a faint comparison line (R9.1).
struct TrendChart: View {
    var parameter: Parameter
    var current: [StationPoint]
    var previous: [StationPoint]
    var threshold: Double?

    var body: some View {
        Chart {
            if !previous.isEmpty {
                ForEach(previous) { point in
                    LineMark(
                        x: .value("Stesen", point.code),
                        y: .value(parameter.shortLabel, point.value),
                        series: .value("Misi", "Sebelum")
                    )
                    .foregroundStyle(Theme.accent.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 3]))
                }
            }

            ForEach(current) { point in
                LineMark(
                    x: .value("Stesen", point.code),
                    y: .value(parameter.shortLabel, point.value),
                    series: .value("Misi", "Kini")
                )
                .foregroundStyle(Theme.accent)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .symbol {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 7, height: 7)
                }
            }

            if let threshold, parameter == .turbidity {
                RuleMark(y: .value("Had", threshold))
                    .foregroundStyle(Theme.critical.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(String(format: "Had %.0f %@", threshold, parameter.unit))
                            .font(.caption2)
                            .foregroundStyle(Theme.critical)
                    }
            }
        }
        .chartYAxisLabel(parameter.unit.isEmpty ? parameter.shortLabel : parameter.unit)
        .chartLegend(.hidden)
        .frame(height: 190)
    }
}
