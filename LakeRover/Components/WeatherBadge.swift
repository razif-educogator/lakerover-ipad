import SwiftUI

struct WeatherBadge: View {
    var summary: WeatherSummary?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: summary?.symbolName ?? "questionmark.circle")
            Text(summary.map { "\($0.condition) \(Int($0.temperatureC.rounded()))°C" } ?? Localization.t("Cuaca tidak tersedia"))
        }
        .font(.caption2.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemFill), in: Capsule())
        .foregroundStyle(.secondary)
    }
}
