import SwiftUI

struct MissionRow: View {
    var mission: Mission
    var weather: WeatherSummary?
    var selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            LakeThumbnail(seed: mission.lakeName.count)
                .frame(width: 64, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text(mission.lakeName)
                    .font(.subheadline.weight(.semibold))
                Text(metaLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    WeatherBadge(summary: weather)
                    if mission.state == .draft {
                        StatusPill(text: "Draf", symbol: "pencil", tint: Theme.warning)
                    } else if mission.state == .completed {
                        StatusPill(text: "Lengkap", symbol: "checkmark", tint: Theme.success)
                    }
                }
            }

            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(selected ? Theme.accent.opacity(0.12) : Theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(selected ? Theme.accent : Theme.hairline, lineWidth: selected ? 1.6 : 1)
        )
    }

    private var metaLine: String {
        let stations = "\(mission.stations.count) stesen"
        let length = String(format: "%.1f km", mission.routeLengthM / 1000)
        let date = mission.plannedDate.formatted(.dateTime.day().month(.wide).year())
        return "\(stations) · \(length) · \(date)"
    }
}

struct LakeThumbnail: View {
    var seed: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.accent.opacity(0.16))
            Wave(phase: Double(seed % 6))
                .stroke(Theme.accent.opacity(0.7), lineWidth: 2)
                .frame(height: 14)
                .offset(y: 6)
            Image(systemName: "water.waves")
                .font(.caption)
                .foregroundStyle(Theme.accent)
                .offset(y: -8)
        }
    }
}
