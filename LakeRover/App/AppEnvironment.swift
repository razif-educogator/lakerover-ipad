import Foundation
import Observation
import SwiftData

/// The single object every screen reads from. Owns the store, the rover link and the
/// services that translate telemetry into persisted state.
@MainActor
@Observable
final class AppEnvironment {
    enum Phase {
        case splash
        case running
    }

    var phase: Phase = .splash
    var isDemo = false

    let container: ModelContainer
    let context: ModelContext
    let router = AppRouter()
    let telemetry = TelemetryStore()
    let alerts: AlertCenter
    let runtime: MissionRuntime
    let showcase = ShowcaseCoordinator()
    let weather = WeatherProvider()

    var client: any RoverClient
    var tagReader: any CartridgeTagReader = SimulatedTagReader()
    var settings: AppSettings

    private var telemetryTask: Task<Void, Never>?

    init() {
        let schema = Schema([Mission.self, Station.self, Sample.self, RoverAlert.self, AppSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // A demo build has nothing worth recovering: if the store is incompatible, start fresh.
        if let container = try? ModelContainer(for: schema, configurations: configuration) {
            self.container = container
        } else {
            self.container = try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            )
        }
        // Everything shares the container's main context so `@Query` sees every change.
        let context = self.container.mainContext
        context.autosaveEnabled = true
        self.context = context

        SeedDataLoader.loadIfNeeded(into: context)
        let settings = SeedDataLoader.settings(in: context)
        self.settings = settings
        Localization.language = settings.appLanguage
        self.alerts = AlertCenter(context: context)
        self.runtime = MissionRuntime(context: context)
        self.client = SimulatedRoverClient()
    }

    // MARK: Derived state used by shared chrome

    var unreadAlertCount: Int { alerts.unreadCount }
    /// Keeps plain-`String` lookups in step with `Text` (see `Localization`).
    var currentLanguage: AppLanguage {
        let language = settings.appLanguage
        Localization.language = language
        return language
    }
    var bannerAlert: RoverAlert? { alerts.banner }
    var hasActiveMission: Bool { runtime.hasActiveMission }
    var language: AppLanguage { currentLanguage }

    func dismissBanner() { alerts.dismissBanner() }

    // MARK: Session lifecycle

    /// Splash → tabs. The demo client is the only client in v1.
    func enterApp(demo: Bool, startingTab: MainTab = .misi) {
        isDemo = demo
        beginTelemetry()
        router.go(startingTab)
        phase = .running
    }

    /// Long-press on the Splash logo: demo mission at 5×, pre-selected, tour running.
    func startShowcaseSession() {
        isDemo = true
        beginTelemetry()
        if let mission = SeedDataLoader.demoMission(in: context) {
            startMission(mission)
        }
        client.speedMultiplier = FeatureFlags.showcaseSpeedMultiplier
        phase = .running
    }

    func startMission(_ mission: Mission) {
        mission.state = .active
        runtime.setActive(mission)
        alerts.reset()
        telemetry.reset()
        beginTelemetry()
        let route = runtime.route()
        send(.loadRoute(route))
        send(.start)
    }

    func endSession() {
        telemetryTask?.cancel()
        telemetryTask = nil
        (client as? SimulatedRoverClient)?.stop()
        client = SimulatedRoverClient()
        telemetry.reset()
        runtime.setActive(nil)
        showcase.exit(env: self)
        phase = .splash
    }

    /// Fire-and-forget: the UI never waits on the rover.
    func send(_ command: RoverCommand) {
        Task { try? await client.send(command) }
    }

    private func beginTelemetry() {
        guard telemetryTask == nil else { return }
        let stream = client.telemetry()
        telemetryTask = Task { [weak self] in
            for await frame in stream {
                guard let self else { return }
                self.telemetry.ingest(frame)
                self.runtime.ingest(frame)
                self.alerts.ingest(frame, thresholds: self.thresholds)
                if let sampling = frame.sampling {
                    self.tagReader.expectedTag = sampling.cartridgeID
                }
            }
        }
    }

    private var thresholds: AlertEngine.Thresholds {
        AlertEngine.Thresholds(lowBatteryPct: settings.lowBatteryThreshold)
    }
}
