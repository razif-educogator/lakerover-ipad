import SwiftUI

/// Status is never colour alone: every pill carries an icon and a word.
struct StatusPill: View {
    var text: LocalizedStringKey
    var symbol: String
    var tint: Color
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(filled ? tint : tint.opacity(0.14), in: Capsule())
        .foregroundStyle(filled ? Color.white : tint)
    }
}

struct DemoBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "play.circle.fill")
            Text("Demo")
        }
        .font(.caption2.weight(.bold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.accent.opacity(0.16), in: Capsule())
        .foregroundStyle(Theme.accent)
        .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1))
    }
}
