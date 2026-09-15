import SwiftUI

/// The "Status rover" card on the Live map (R3.3).
struct RoverStatusPanel: View {
    var telemetry: Telemetry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Status rover")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            KeyValueRow("Kelajuan", String(format: "%.1f m/s", telemetry.speedMps))
            Divider()
            KeyValueRow("Arah", telemetry.headingText)
            Divider()
            KeyValueRow(
                "Bateri",
                "\(telemetry.batteryPct)%",
                tint: telemetry.batteryPct < 20 ? Theme.critical : nil
            )
            Divider()
            KeyValueRow("Solar", String(format: "%.0f W", telemetry.solarW))
            Divider()
            HStack {
                Text("Sambungan").foregroundStyle(.secondary)
                Spacer(minLength: 12)
                HStack(spacing: 4) {
                    Text(telemetry.linkType)
                    SignalBars(quality: telemetry.linkQuality)
                }
                .fontWeight(.medium)
            }
            .font(.subheadline)
            .padding(.vertical, 7)
        }
        .frame(width: 190)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }
}

struct SignalBars: View {
    var quality: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(1...4, id: \.self) { level in
                RoundedRectangle(cornerRadius: 1)
                    .fill(level <= quality ? Theme.accent : Color(.tertiaryLabel))
                    .frame(width: 3, height: 4 + CGFloat(level) * 2.5)
            }
        }
        .accessibilityLabel("Kualiti pautan \(quality) daripada 4")
    }
}
