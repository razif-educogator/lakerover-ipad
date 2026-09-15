import SwiftUI

/// The judge-facing caption strip for Showcase mode (R14.2). Rendered by `MainTabView`
/// so it survives every tab and push.
struct ShowcaseOverlay: View {
    @Environment(AppEnvironment.self) private var env

    private var showcase: ShowcaseCoordinator { env.showcase }

    var body: some View {
        if showcase.isActive {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    stepDots
                    Spacer(minLength: 8)
                    Text("\(showcase.stepIndex + 1) / \(ShowcaseCoordinator.steps.count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Button {
                        showcase.exit(env: env)
                    } label: {
                        Label("Keluar", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.accent)
                        Text(showcase.step.captionMS)
                            .font(.subheadline.weight(.medium))
                        Text(showcase.step.captionEN)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Button {
                        showcase.next(env: env)
                    } label: {
                        HStack(spacing: 6) {
                            Text(showcase.isLastStep ? "Tamat" : "Seterusnya")
                            Image(systemName: showcase.isLastStep ? "checkmark" : "arrow.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1)
            )
            .shadow(radius: 10, y: 4)
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, Theme.tight)
            .frame(maxWidth: 720)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.25), value: showcase.stepIndex)
        }
    }

    private var title: String {
        let step = showcase.step
        return "\(step.titleMS.uppercased()) · \(step.titleEN.uppercased())"
    }

    private var stepDots: some View {
        HStack(spacing: 5) {
            ForEach(ShowcaseCoordinator.steps) { step in
                Capsule()
                    .fill(step.id <= showcase.stepIndex ? Theme.accent : Color(.tertiaryLabel))
                    .frame(width: step.id == showcase.stepIndex ? 18 : 7, height: 7)
            }
        }
    }
}
