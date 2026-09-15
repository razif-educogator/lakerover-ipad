import SwiftData
import SwiftUI

@main
struct LakeRoverApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
                .modelContainer(env.container)
                .tint(Theme.accent)
                .environment(\.locale, env.language.locale)
                .task { await DebugAutorun.run(env: env) }
        }
    }
}
