import SwiftUI

struct StationTimeline: View {
    var stations: [Station]
    var currentIndex: Int?
    var onSelect: (Station) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(stations) { station in
                Button { onSelect(station) } label: {
                    row(station)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func row(_ station: Station) -> some View {
        let isCurrent = station.index == currentIndex
        return HStack(spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(station.status.tint)
                        .frame(width: 26, height: 26)
                    Text(station.shortCode)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                }
                if station.index != (stations.last?.index ?? 0) {
                    Rectangle()
                        .fill(station.status == .done ? Theme.success : Theme.hairline)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .font(.subheadline.weight(isCurrent ? .semibold : .medium))
                Text(station.completedAt?.formatted(date: .omitted, time: .shortened) ?? "—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            StatusPill(
                text: station.status.label,
                symbol: station.status.symbol,
                tint: station.status.tint
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            isCurrent
                ? Theme.accent.opacity(0.10)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }
}
