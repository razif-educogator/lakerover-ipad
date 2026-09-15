import SwiftUI

/// Top banner shown on whatever screen is open when a Kritikal alert appears (R10.5).
struct CriticalBanner: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        if let alert = env.bannerAlert {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.octagon.fill")
                VStack(alignment: .leading, spacing: 1) {
                    Text(alert.title).font(.subheadline.weight(.semibold))
                    Text(alert.detail).font(.caption)
                }
                Spacer(minLength: 8)
                Button {
                    env.router.go(.amaran)
                    env.dismissBanner()
                } label: {
                    Text("Butiran").font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(Theme.critical)

                Button {
                    env.dismissBanner()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
            .background(Theme.critical, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .shadow(radius: 8, y: 3)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
