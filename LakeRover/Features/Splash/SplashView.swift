import SwiftUI

struct SplashView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var connection: ConnectionState = .searching

    var body: some View {
        ZStack {
            Theme.screenBackground.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 12)

                LogoLockup()
                    // Long-press starts the guided judge tour (R14.1).
                    .onLongPressGesture(minimumDuration: 0.8) {
                        env.showcase.start(env: env)
                    }
                    .accessibilityHint("Tekan lama untuk mod pameran")

                LakeIllustration()
                    .frame(maxWidth: 460)
                    .aspectRatio(4.0 / 3.0, contentMode: .fit)

                Text("Satu lokasi. Satu sampel. Satu impak.")
                    .font(.headline)

                ConnectionCard(state: connection)
                    .frame(maxWidth: 460)

                VStack(spacing: 12) {
                    PrimaryButton(primaryTitle, enabled: connection != .searching) {
                        env.enterApp(demo: true, startingTab: .misi)
                    }
                    Button {
                        env.enterApp(demo: true, startingTab: .misi)
                    } label: {
                        Text("Cuba mod demo (tanpa rover)")
                            .font(.footnote)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accent)
                }
                .frame(maxWidth: 320)

                Spacer(minLength: 8)

                Text("“Dari Tasik ke Data. Dari Data ke Tindakan.”")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(Theme.gutter * 1.5)
            .frame(maxWidth: 620)
        }
        // A safe-area inset rather than an overlay: it reserves its own strip at the bottom,
        // so it can never sit on top of the Mula button or the connection card.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            creditLine
        }
        .task { await attemptConnection() }
    }

    private var creditLine: some View {
        Text("Dibangunkan oleh Razif Razak menerusi Xcode")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, Theme.gutter)
    }

    private var primaryTitle: LocalizedStringKey {
        connection == .notFound ? "Mula (mod demo)" : "Mula"
    }

    /// R1.2/R1.3: look for a real rover, give up after the timeout, keep demo mode open.
    private func attemptConnection() async {
        connection = .searching
        let probe = NetworkRoverClient()
        let found: Bool = await {
            do {
                try await probe.connect()
                return true
            } catch {
                return false
            }
        }()
        // Keep the attempt visible long enough to read, without the full 10 s timeout.
        try? await Task.sleep(for: .seconds(1.6))
        connection = found
            ? .connected(name: env.roverName, link: "4G", batteryPct: 78, satellites: 9)
            : .notFound
    }
}
