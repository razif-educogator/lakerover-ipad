import SwiftUI

/// Lake weather on the Live map, sitting under `RoverStatusPanel`. Deliberately mirrors that
/// panel's width and chrome so the two read as one column. Seed data — no live updates.
struct WeatherCard: View {
    var summary: WeatherSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Cuaca")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            HStack(spacing: 10) {
                Image(systemName: summary.symbolName)
                    .font(.title2)
                    .symbolRenderingMode(.multicolor)

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(Int(summary.temperatureC.rounded()))°C")
                        .font(Theme.numberFont)
                        .monospacedDigit()
                    Text(summary.condition)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
        // Same 190 pt content width + 12 pt padding as RoverStatusPanel, so both cards align.
        .frame(width: 190, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }
}
