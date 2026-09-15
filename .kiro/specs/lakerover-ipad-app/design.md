# Design — LakeRover iPad app (v1)

## Overview

SwiftUI + SwiftData iPad app. A single `RoverClient` abstraction feeds an `AsyncStream<Telemetry>` into a `TelemetryStore`; view models observe the store, and an `AlertEngine` derives alerts from the same stream. Demo mode swaps in `SimulatedRoverClient` — nothing else changes.

```
┌──────────────┐   AsyncStream<Telemetry>   ┌────────────────┐
│ RoverClient  │ ─────────────────────────▶ │ TelemetryStore │──▶ ViewModels ──▶ Views
│ (sim / net)  │ ◀──── commands ─────────── │  (@Observable) │
└──────────────┘                            └───────┬────────┘
                                                    ▼
                                             AlertEngine ──▶ SwiftData (Alert)
```

## Data model (SwiftData)

```swift
@Model final class Mission {
  var id: UUID; var name: String; var lakeName: String; var plannedDate: Date
  var state: MissionState            // draft, planned, active, paused, completed
  var routeLengthM: Double
  @Relationship(deleteRule: .cascade) var stations: [Station]
  @Relationship(deleteRule: .cascade) var samples: [Sample]
  var turbidityThresholdNTU: Double  // default 15
}

@Model final class Station {
  var id: UUID; var index: Int; var name: String; var zone: String
  var latitude: Double; var longitude: Double; var depthM: Double?
  var targetParameters: [Parameter]  // .turbidity, .temperature, .pH, .dissolvedOxygen, .conductivity
  var status: StationStatus          // waiting, inProgress, done, skipped
  var completedAt: Date?
  var mission: Mission?
}

@Model final class Sample {
  var id: UUID; var code: String     // LR-2026-004
  var station: Station?; var mission: Mission?
  var takenAt: Date; var latitude: Double; var longitude: Double
  var volumeL: Double; var targetVolumeL: Double
  var tagID: String?; var status: SampleStatus   // waiting, inProgress, done, cancelled
  var turbidityNTU: Double?; var temperatureC: Double?; var pH: Double?; var dissolvedOxygenMgL: Double?
  var studentNote: String
}

@Model final class RoverAlert {
  var id: UUID; var createdAt: Date; var severity: Severity   // critical, warning, info
  var kind: AlertKind                // lowBattery, lowFlow, obstacle, linkLost, waterIngress, custom
  var title: String; var detail: String
  var primaryAction: AlertAction     // returnHome, retrySample, showOnMap, none
  var dismissed: Bool; var read: Bool
}

@Model final class AppSettings {      // single row
  var language: String; var autoReturnEnabled: Bool; var autoReturnThreshold: Int
  var autonomousMode: Bool; var powerSaveMode: Bool; var cloudSync: Bool
  var notificationLevel: NotificationLevel; var mapStyle: MapLayer; var stationSpacingM: Int
}
```

Value types (not persisted): `Telemetry`, `RoverCommand`, `SamplingPhase`, `PowerBreakdown`.

```swift
struct Telemetry: Sendable {
  var timestamp: Date
  var coordinate: CLLocationCoordinate2D; var headingDeg: Double; var speedMps: Double
  var batteryPct: Int; var batteryRatePctPerMin: Double; var solarW: Double
  var linkQuality: Int /*0–4*/; var linkType: String; var gpsSatellites: Int
  var sampling: SamplingTelemetry?   // phase, pumpFlowLpm, filledL, targetL, live readings, cartridgeID
  var powerBreakdown: PowerBreakdown // thrusterW, pumpW, linkW, computeW, sensorsW
  var obstacleDetected: Bool; var waterIngress: Bool
  var currentStationIndex: Int?; var etaToStationS: Double?; var distanceToStationM: Double?
}

enum RoverCommand: Sendable {
  case loadRoute([Station]); case start; case pause; case resume
  case emergencyStop; case resumeAfterStop; case returnHome
  case skipStation(Int); case startSampling(stationIndex: Int, parameters: [Parameter])
  case stopSampling; case restartSampling
  case setAutoReturn(enabled: Bool, thresholdPct: Int); case setAutonomous(Bool); case setPowerSave(Bool)
}

protocol RoverClient: Sendable {
  var isDemo: Bool { get }
  func connect() async throws
  func telemetry() -> AsyncStream<Telemetry>
  func send(_ command: RoverCommand) async throws
}
```

## Services

- **SimulatedRoverClient** — loads `Resources/seed/demo-cenderoh.json` (6 stations on Tasik Cenderoh), moves the rover along the route at ~1.2 m/s, runs a scripted sampling sequence at each station (~45 s), drains battery ~0.3 %/min, generates solar 20–40 W with noise, and injects: an obstacle at station 3, low flow at station 4, battery 20 % before station 5. `speedMultiplier` (1× / 5×). Deterministic given a seed so tests are stable.
- **NetworkRoverClient** — `URLSessionWebSocketTask`; JSON messages `{ "type": "telemetry", ... }` / `{ "type": "command", ... }`. Reconnects with backoff; emits `linkQuality = 0` while disconnected. Stubbed in v1 (connect throws `RoverError.notAvailable`) but fully typed.
- **TelemetryStore** (`@Observable`) — latest `Telemetry`, ring buffer of the last 30 min for charts, session solar history, derived `estimatedRuntime`.
- **AlertEngine** — pure function `evaluate(telemetry, previous, settings) -> [RoverAlert]` plus a debounce so each rule fires once per condition. Rules per R10.
- **CartridgeTagReader** protocol — `readTag() async throws -> String`; `NFCCartridgeTagReader` (Core NFC) and `SimulatedTagReader` (returns the seed cartridge ID after 1.5 s).
- **CSVExporter** — `Sample` → RFC 4180 CSV; `PDFReportRenderer` — `ImageRenderer` on a `ReportPage` SwiftUI view (A4 portrait).
- **WeatherProvider** — WeatherKit if entitlement present, otherwise seed weather; interface returns `WeatherSummary?`.
- **SeedDataLoader** — on first launch inserts three missions (Cenderoh, Raban, Bukit Merah) and prior-mission samples so Insights has comparison data.

## AR model integration (Reality Composer)

The team authors the rover in Reality Composer on iPad and exports `Rover.reality` (USDZ is not used: it drops behaviours). The app treats the file as a black box and talks to it only through two NotificationCenter channels:

```
Reality file ──RealityKit.NotifyAction──▶ app   (userInfo["RealityKit.NotifyAction.Identifier"])
app ──RealityKit.NotificationTrigger──▶ Reality file
      (userInfo["RealityKit.NotificationTrigger.Scene"], ["…Identifier"])
```

Contract (`docs/reality-composer-contract.md`):

| Direction | Identifier | Reality Composer behaviour |
|---|---|---|
| model → app | `antenaGPS`, `panelSolar`, `kamera360`, `pensampel`, `pendorong` | Trigger *Tap* on the object → *Emphasize* → *Notify* |
| model → app | `samplingStep1` … `samplingStep6` | posted by the sampling animation at each step so the app's `StepBar` stays in sync |
| app → model | `showAll`, `showPensampel`, `showElektronik`, `showPropulsi` | Trigger *Notification* → *Hide/Show* groups |
| app → model | `playSampling` | Trigger *Notification* → animation sequence pump → cartridge → bottle |
| app → model | `scaleReal`, `scaleTabletop` | Trigger *Notification* → *Scale* action |

`RoverARView` is a `UIViewRepresentable` over `ARView`. `makeUIView` loads the entity with `Entity(named: "Rover")`, anchors it to a horizontal plane and registers one `NotifyAction` observer that maps identifiers to `RoverComponent`. `updateUIView` posts triggers when the selected group or scale changes. On the Simulator `cameraMode = .nonAR` with a world anchor and orbit gestures. `FeatureFlags.arEnabled` is `true`; the flag now only gates the AR/non-AR camera choice.

Why this matters for the pitch: the model is a real artefact the students build and iterate themselves, on the same iPad, with no code — the app just gives it a voice.

## Navigation

```
RootView
├── SplashView                       (no tabs)
└── MainTabView (5 tabs)
    ├── Live     → LiveMapView  ─sheet─▶ StationDetailView, CameraSheet
    ├── Misi     → MissionProgressView / MissionPickerView (when no active mission)
    │              ─push─▶ SamplingView, MissionEditorView, RoverModelView
    ├── Sampel   → SamplesView (list + detail, NavigationSplitView)
    ├── Data     → InsightsView
    └── Amaran   → AlertsView
    header icons → PowerView (sheet), SettingsView (sheet)
```
Demo badge and critical-alert banner are overlaid by `MainTabView`, not by individual screens.

## Screens → components (from storyboard-v1)

| # | Screen | Key components |
|---|--------|----------------|
| 1 | Splash | `LogoLockup`, `ConnectionCard`, `PrimaryButton` |
| 2 | Mission picker | `SearchField`, `FilterChips`, `MissionRow` (thumbnail, meta, `WeatherBadge`) |
| 3 | Live map | `Map` + `RouteOverlay`, `StationAnnotation`, `RoverAnnotation`, `RoverStatusPanel`, `LayerChips`, `MapControls` (recentre, camera, emergency stop), `NextStationCard` |
| 4 | Station detail | `MiniMap`, `KeyValueList`, `ParameterChecklist` |
| 5 | Rover model | `RoverARView` (UIViewRepresentable → `ARView`), `GroupChips`, `ComponentInfoCard`, scale toggle, coaching overlay |
| 6 | Mission progress | `ProgressHeader`, `StationTimeline` |
| 7 | Sampling | `StepBar`, `FlowDiagram` (animated), `LiveReadingsPanel`, `FillProgress`, `CameraThumb` |
| 8 | Samples | `SampleRow`, `SampleDetailPane`, `SensorTable`, `NoteField` |
| 9 | Insights | `ParameterChips`, `RangeChips`, `TrendChart` (Swift Charts), `HeatMapGrid`, `StatCard`, `AttentionCard`, `RecommendationCard` |
| 10 | Alerts | `SeverityChips`, `AlertCard` (severity bar, primary action, Abaikan) |
| 11 | Power | `BatteryRing`, `SolarBars`, `RuntimeCard`, `ConsumptionList`, `SettingToggleRow` |
| 12 | Settings | `SettingsRow` list, `LanguagePicker`, `AboutView` |

Shared: `StatusPill`, `ChipRow`, `PrimaryButton`, `DestructiveButton`, `DemoBadge`, `CriticalBanner`, `Theme`.

## Error handling

- Rover errors surface as alerts (link lost) or inline messages (command failed → toast "Arahan gagal dihantar, cuba lagi").
- NFC unavailable / cancelled → the Tag step offers "Masukkan ID secara manual".
- Export failures → alert dialog with the error's localized description.
- Never block the UI on the rover; every command is fire-and-await with a 3 s timeout.

## Testing strategy

- `SimulatedRoverClientTests` — route completion, scripted alerts, deterministic seed.
- `AlertEngineTests` — each rule fires once and only once per condition; thresholds respect settings.
- `SamplingViewModelTests` — phase transitions, Hentikan/Ulang behaviour, tag attach.
- `InsightsViewModelTests` — averages, highest station, attention card threshold.
- `CSVExporterTests` — header, escaping, row count.
- View models are tested with an in-memory `ModelContainer`.

## Showcase mode
`ShowcaseCoordinator` (`@Observable`) holds a fixed step list (Live Map → Sampling → AR model → Insights), starts the simulated client at 5×, drives tab selection, and supplies `caption` (BM/EN) to a `ShowcaseOverlay` rendered by `MainTabView`. It is started by a long-press on the Splash logo and can be exited from any step.

## Out of scope for v1
Real rover firmware protocol beyond the JSON contract, multi-user accounts, Google Drive API sync (share sheet only).
