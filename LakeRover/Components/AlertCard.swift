import SwiftUI

struct AlertCard: View {
    var alert: RoverAlert
    var onPrimary: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(alert.severity.tint)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: alert.severity.symbol)
                        .foregroundStyle(alert.severity.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.title)
                            .font(.subheadline.weight(.semibold))
                        Text(alert.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Text(alert.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }

                HStack(spacing: 10) {
                    if alert.primaryAction != .none {
                        Button(action: onPrimary) {
                            Text(alert.primaryAction.label)
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.accent, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    Button(action: onDismiss) {
                        Text("Abaikan")
                            .font(.footnote)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 0)
                }
            }
            .padding(12)
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }
}
