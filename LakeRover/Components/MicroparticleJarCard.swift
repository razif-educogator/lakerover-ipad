import SwiftUI

/// Mikropartikel during a sampling run: water is filtered into a jar and the jar tag is read.
/// Deliberately *not* a seventh `SamplingPhase` — the six steps are fixed by the
/// Reality Composer contract, so this runs alongside them instead.
struct MicroparticleJarCard: View {
    var sampling: SamplingTelemetry?
    var enabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Mikropartikel").sectionTitle()
                StatusPill(text: "analisis makmal", symbol: "flask.fill", tint: Theme.warning)
                Spacer(minLength: 0)
            }

            if !enabled {
                Text("Tidak dipilih untuk stesen ini.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .center, spacing: 14) {
                    JarGlyph(fillFraction: fillFraction, filtering: isFiltering)

                    VStack(alignment: .leading, spacing: 6) {
                        stepLine(
                            symbol: "line.3.horizontal.decrease.circle",
                            text: filterText,
                            active: isFiltering,
                            complete: fillFraction >= 0.999
                        )
                        stepLine(
                            symbol: "wave.3.right",
                            text: jarText,
                            active: sampling?.mpfJarTagged == false && isFiltering,
                            complete: sampling?.mpfJarTagged ?? false
                        )
                    }
                }

                ProgressView(value: fillFraction)
                    .tint(Theme.accent)

                Text("Tiada bacaan lapangan — balang dihantar ke makmal untuk kiraan mikroplastik dan mikrofiber.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var isFiltering: Bool {
        guard let sampling else { return false }
        return sampling.phase == .sample
    }

    private var fillFraction: Double {
        guard let sampling, sampling.mpfTargetL > 0 else { return 0 }
        return min(1, sampling.mpfFilteredL / sampling.mpfTargetL)
    }

    private var filterText: String {
        guard let sampling else { return Localization.t("Menunggu pensampelan bermula") }
        return String(
            format: Localization.t("Ditapis %.1f / %.1f L"),
            sampling.mpfFilteredL,
            sampling.mpfTargetL
        )
    }

    private var jarText: String {
        guard let sampling, sampling.mpfJarTagged else {
            return Localization.t("Tag balang belum dibaca")
        }
        return String(format: Localization.t("Balang %@ ditag"), sampling.mpfJarID)
    }

    private func stepLine(symbol: String, text: String, active: Bool, complete: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: complete ? "checkmark.circle.fill" : symbol)
                .foregroundStyle(complete ? Theme.success : (active ? Theme.accent : Color.secondary))
            Text(text)
                .font(.footnote.weight(active || complete ? .medium : .regular))
                .foregroundStyle(active || complete ? .primary : .secondary)
        }
    }
}

/// The MPF collection jar, filling as water is filtered through it.
struct JarGlyph: View {
    var fillFraction: Double
    var filtering: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Theme.accent, lineWidth: 2)
                .frame(width: 38, height: 52)
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.accent.opacity(0.55))
                .frame(width: 32, height: max(2, 46 * fillFraction))
                .padding(.bottom, 3)
                .animation(.easeInOut(duration: 0.4), value: fillFraction)
            // Filter mesh across the neck
            Rectangle()
                .fill(Theme.accent.opacity(filtering ? 0.9 : 0.35))
                .frame(width: 30, height: 3)
                .offset(y: -49)
        }
        .frame(width: 44, height: 58)
        .accessibilityLabel("Balang mikropartikel")
        .accessibilityValue("\(Int(fillFraction * 100)) peratus penuh")
    }
}
