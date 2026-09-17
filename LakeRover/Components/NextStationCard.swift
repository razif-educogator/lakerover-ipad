import CoreLocation
import SwiftUI

/// "Seterusnya: Stesen S4 · Zon Selatan · 120 m · ETA 2 min" with Butiran / Langkau (R3.8).
struct NextStationCard: View {
    var station: Station?
    var distanceM: Double?
    var etaSeconds: Double?
    var samplingInProgress: Bool
    var onDetails: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let station {
                HStack(spacing: 6) {
                    Text(samplingInProgress ? "Sedang diproses:" : "Seterusnya:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Stesen \(station.shortCode)")
                        .font(.subheadline.weight(.semibold))
                    if samplingInProgress {
                        StatusPill(text: "Sedang diproses", symbol: "arrow.triangle.2.circlepath", tint: Theme.accent)
                    }
                }
                Text(detailLine(for: station))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(String(format: "%.5f, %.5f", station.coordinate.latitude, station.coordinate.longitude), systemImage: "mappin.and.ellipse")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    SecondaryButton("Butiran", action: onDetails)
                    SecondaryButton("Langkau", action: onSkip)
                }
            } else {
                Text("Misi selesai — semua stesen telah disampel.")
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private func detailLine(for station: Station) -> String {
        var parts = [station.name]
        if let distanceM { parts.append(String(format: "%.0f m", distanceM)) }
        if let etaSeconds, etaSeconds > 0 {
            parts.append("ETA \(max(1, Int((etaSeconds / 60).rounded()))) min")
        }
        return parts.joined(separator: " · ")
    }
}
