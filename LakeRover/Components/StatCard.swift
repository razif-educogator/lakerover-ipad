import SwiftUI

struct StatCard: View {
    var title: LocalizedStringKey
    var value: String
    var footnote: String?
    var footnoteTint: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(Theme.numberFont)
                .monospacedDigit()
            if let footnote {
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(footnoteTint ?? .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 12)
    }
}

/// "Perhatian" — a station over the threshold (R9.4).
struct AttentionCard: View {
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Perhatian", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.critical)
            Text(text)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.critical.opacity(0.10), in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.critical.opacity(0.35), lineWidth: 1)
        )
    }
}

/// "Cadangan tindakan" — the card the Showcase run ends on (R14.3).
struct RecommendationCard: View {
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Cadangan tindakan", systemImage: "lightbulb.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.warning)
            Text(text)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.warning.opacity(0.4), lineWidth: 1)
        )
    }
}
