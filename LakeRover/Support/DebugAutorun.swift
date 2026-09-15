import Foundation

/// Drives Showcase mode without a finger on the screen. Used to verify the demo path in the
/// Simulator: `-autorunShowcase` starts the tour and advances every few seconds.
/// Debug builds only.
@MainActor
enum DebugAutorun {
    static var isRequested: Bool {
        #if DEBUG
        CommandLine.arguments.contains("-autorunShowcase")
        #else
        false
        #endif
    }

    static func run(env: AppEnvironment, secondsPerStep: Double = 6) async {
        guard isRequested else { return }
        try? await Task.sleep(for: .seconds(2))
        env.showcase.start(env: env)
        for _ in ShowcaseCoordinator.steps.dropFirst() {
            try? await Task.sleep(for: .seconds(secondsPerStep))
            env.showcase.next(env: env)
        }
    }
}
