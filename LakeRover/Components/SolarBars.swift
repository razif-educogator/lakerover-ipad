import Charts
import SwiftUI

struct SolarBars: View {
    var samples: [TelemetryStore.SolarSample]
    var currentW: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(format: "%.0f W", currentW))
                .font(Theme.bigNumberFont)
                .monospacedDigit()

            if samples.isEmpty {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 96)
                    .overlay(
                        Text("Menunggu data solar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    )
            } else {
                Chart(samples) { sample in
                    BarMark(
                        x: .value("Minit", sample.minute),
                        y: .value("Watt", sample.watts)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.85))
                    .cornerRadius(2)
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
                }
                .frame(height: 96)
            }

            Text("Jana sesi ini · setiap minit")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct RuntimeCard: View {
    var runtimeText: String
    var stationsCovered: Int

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Anggaran masa operasi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(runtimeText)
                    .font(Theme.numberFont)
            }
            Spacer(minLength: 8)
            Text("cukup untuk \(stationsCovered) stesen lagi")
                .font(.caption)
                .foregroundStyle(Theme.accent)
                .multilineTextAlignment(.trailing)
        }
        .padding(12)
        .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }
}

struct ConsumptionList: View {
    var breakdown: PowerBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Penggunaan kuasa").sectionTitle()
            ForEach(Array(breakdown.rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    Text(row.label)
                        .font(.footnote)
                        .frame(width: 132, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.tertiarySystemFill))
                            Capsule()
                                .fill(Theme.accent)
                                .frame(width: geo.size.width * min(1, row.watts / 8))
                        }
                    }
                    .frame(height: 8)
                    Text(String(format: "%.0f W", row.watts))
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }
}

struct SettingToggleRow: View {
    var title: LocalizedStringKey
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline)
                if let subtitle {
                    Text(subtitle).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .tint(Theme.accent)
    }
}
