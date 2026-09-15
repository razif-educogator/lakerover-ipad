import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ZStack {
            switch env.phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .running:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: env.phase == .running)
    }
}
