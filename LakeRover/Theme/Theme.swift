import SwiftUI

/// Single source of truth for colour, spacing and corner radius.
enum Theme {
    // MARK: Colours
    static let accent = Color("LakeBlue")
    static let success = Color("StatusSuccess")
    static let warning = Color("StatusWarning")
    static let critical = Color("StatusCritical")

    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let screenBackground = Color(.systemGroupedBackground)
    static let hairline = Color(.separator)
    static let waiting = Color(.tertiaryLabel)

    // MARK: Metrics
    static let corner: CGFloat = 14
    static let cardCorner: CGFloat = 18
    static let gutter: CGFloat = 16
    static let tight: CGFloat = 8

    // MARK: Type
    static let numberFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let bigNumberFont = Font.system(size: 34, weight: .bold, design: .rounded)
    static let labelFont = Font.footnote.weight(.medium)
}

extension View {
    /// Standard card chrome used across every screen.
    func cardStyle(padding: CGFloat = Theme.gutter) -> some View {
        self
            .padding(padding)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
    }

    func sectionTitle() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}
