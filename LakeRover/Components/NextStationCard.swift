import CoreLocation
import SwiftUI

/// "Seterusnya: Stesen S4 · Zon Selatan · 120 m · ETA 2 min" with Butiran / Langkau (R3.8).
/// Collapsible: the header stays, the detail collapses away so the presenter can show more map.
struct NextStationCard: View {
    var station: Station?
    var distanceM: Double?
    var etaSeconds: Double?
    var samplingInProgress: Bool
    var isReturning: Bool = false
    /// Owned by the Live map so the choice survives telemetry-driven redraws.
    @Binding var isCollapsed: Bool
    var onDetails: () -> Void
    var onSkip: () -> Void

    private static let animation = Animation.easeInOut(duration: 0.25)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if !isCollapsed {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .animation(Self.animation, value: isCollapsed)
        // Swipe down to collapse, up to expand. `minimumDistance` keeps taps on the
        // Butiran / Langkau buttons working.
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height > 20 {
                        setCollapsed(true)
                    } else if value.translation.height < -20 {
                        setCollapsed(false)
                    }
                }
        )
    }

    // MARK: Header — always visible, and the tap target for collapsing

    private var header: some View {
        Button {
            setCollapsed(!isCollapsed)
        } label: {
            HStack(spacing: 6) {
                if isReturning {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundStyle(Theme.warning)
                    Text("Pulang ke jeti")
                        .font(.subheadline.weight(.semibold))
                } else if let station {
                    Text(samplingInProgress ? "Sedang diproses:" : "Seterusnya:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Stesen \(station.shortCode)")
                        .font(.subheadline.weight(.semibold))
                    if samplingInProgress {
                        StatusPill(text: "Sedang diproses", symbol: "arrow.triangle.2.circlepath", tint: Theme.accent)
                    }
                } else {
                    Text("Misi selesai")
                        .font(.subheadline.weight(.medium))
                }

                Spacer(minLength: 8)

                Image(systemName: isCollapsed ? "chevron.up" : "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            // Whole row is tappable, not just the words.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCollapsed ? "Kembangkan kad stesen" : "Kecilkan kad stesen")
    }

    // MARK: Detail — hidden when collapsed

    @ViewBuilder private var expandedContent: some View {
        if isReturning {
            Text("Rover menjejak semula laluan misi ke Jeti Utama.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if let station {
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
            Text("Semua stesen telah disampel.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func setCollapsed(_ collapsed: Bool) {
        guard isCollapsed != collapsed else { return }
        withAnimation(Self.animation) {
            isCollapsed = collapsed
        }
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
