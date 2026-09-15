# Tasks — LakeRover iPad app (v1)

Work top to bottom. Each task should compile and, where noted, pass tests before moving on. Reference `docs/wireframes/storyboard-v1.png` for every screen.

- [ ] 1. Project scaffold
  - [ ] 1.1 Create `project.yml` (XcodeGen) with targets `LakeRover` (iPad only, iPadOS 18, Swift 6) and `LakeRoverTests`; folder layout per `.kiro/steering/structure.md`
  - [ ] 1.2 Add `Theme.swift`, `Colors.xcassets` (LakeBlue, success, warning, critical), `Localizable.xcstrings` with BM + EN
  - [ ] 1.3 Add `FeatureFlags` (`arEnabled = false`) and `AppEnvironment` for dependency injection
  - [ ] 1.4 `RootView` with placeholder Splash and a 5-tab `MainTabView` (Live, Misi, Sampel, Data, Amaran) + header icons for Tenaga/Tetapan _(R13.1)_

- [ ] 2. Models & persistence
  - [ ] 2.1 SwiftData models: `Mission`, `Station`, `Sample`, `RoverAlert`, `AppSettings` and their enums, per design.md
  - [ ] 2.2 Value types `Telemetry`, `SamplingTelemetry`, `PowerBreakdown`, `RoverCommand`, `Parameter`
  - [ ] 2.3 `SeedDataLoader` + `Resources/seed/*.json` for Cenderoh (6 stations), Raban, Bukit Merah and prior-mission samples _(R2.1, R9.1)_
  - [ ] 2.4 Tests: model round-trip in an in-memory container, seed loads once

- [ ] 3. Rover link
  - [ ] 3.1 `RoverClient` protocol and `TelemetryStore` (`@Observable`, ring buffer, solar history, `estimatedRuntime`)
  - [ ] 3.2 `SimulatedRoverClient`: route playback at 1.2 m/s, scripted sampling per station, battery drain, solar noise, injected events, `speedMultiplier` _(R13.2)_
  - [ ] 3.3 `NetworkRoverClient` stub with WebSocket JSON contract and reconnect skeleton
  - [ ] 3.4 Tests: simulated client finishes the route, is deterministic for a seed, raises the scripted events

- [ ] 4. Alerts engine
  - [ ] 4.1 `AlertEngine.evaluate` with rules: battery < 20 %, low flow, obstacle, link lost, water ingress; debounce per condition _(R10.1)_
  - [ ] 4.2 Wire engine to `TelemetryStore` and persist `RoverAlert`; unread badge on Amaran tab; `CriticalBanner` overlay _(R10.2, R10.5)_
  - [ ] 4.3 Tests: each rule fires exactly once per condition; thresholds follow `AppSettings`

- [ ] 5. Splash & connection _(R1)_
  - [ ] 5.1 `SplashView` with logo lockup, tagline, `ConnectionCard`, Mula, "Cuba mod demo"
  - [ ] 5.2 Connection attempt with 10 s timeout, "Rover tidak dijumpai" state, demo-mode start, `DemoBadge`

- [ ] 6. Mission picker & editor _(R2)_
  - [ ] 6.1 `MissionPickerView`: search, filter chips, `MissionRow` with `WeatherBadge`, Mula misi, Misi baharu
  - [ ] 6.2 `WeatherProvider` (WeatherKit if available, else seed) with graceful fallback
  - [ ] 6.3 `MissionEditorView`: name, lake, date, tap-to-add stations on a map, drag reorder, save as Draf
  - [ ] 6.4 Starting a mission sends `.loadRoute` + `.start` and switches to Live tab

- [ ] 7. Live map _(R3)_
  - [ ] 7.1 `LiveMapView` with MapKit route polyline, `StationAnnotation` (waiting/current/done), `RoverAnnotation` rotated by heading, 1 Hz updates
  - [ ] 7.2 `RoverStatusPanel` (speed, heading, battery, solar, link)
  - [ ] 7.3 `LayerChips`: Satelit / Kedalaman / Kekeruhan with overlays from stored data
  - [ ] 7.4 `MapControls`: recentre, camera sheet (placeholder feed), emergency stop with confirmation banner and "Sambung semula"
  - [ ] 7.5 `NextStationCard` with Butiran → Station Detail sheet, Langkau with confirmation

- [ ] 8. Station detail _(R4)_
  - [ ] 8.1 `StationDetailView`: mini map, key-value rows, `ParameterChecklist`, cartridge line
  - [ ] 8.2 "Mula pensampelan" disabled when rover > 10 m away, with reason; sends `.startSampling`

- [ ] 9. Sampling process _(R7)_
  - [ ] 9.1 `SamplingView`: `StepBar` driven by `SamplingPhase`, animated `FlowDiagram`, `LiveReadingsPanel`, `FillProgress`, `CameraThumb`
  - [ ] 9.2 `CartridgeTagReader` protocol, `SimulatedTagReader`, `NFCCartridgeTagReader`, manual ID fallback
  - [ ] 9.3 Hentikan / Ulang sampel behaviour; save `Sample` on Gerak and return to Live Map
  - [ ] 9.4 Tests: `SamplingViewModel` phase transitions and tag attach

- [ ] 10. Mission progress _(R6)_
  - [ ] 10.1 `MissionProgressView`: `ProgressHeader` (count, %, ETA, remaining distance), `StationTimeline`
  - [ ] 10.2 Jeda/Sambung misi and Pulang ke jeti with confirmation
  - [ ] 10.3 Misi tab shows Mission Picker when no mission is active, otherwise Mission Progress; push to Rover Model from header

- [ ] 11. Samples _(R8)_
  - [ ] 11.1 `SamplesView` as `NavigationSplitView`: list with status chips, `SampleDetailPane` with `SensorTable` and `NoteField`
  - [ ] 11.2 Lihat di peta → Live tab centred on station
  - [ ] 11.3 `CSVExporter` + `ShareLink`; tests for header, escaping, row count

- [ ] 12. Data & insight _(R9)_
  - [ ] 12.1 `InsightsView`: parameter/range chips, `TrendChart` with previous-mission comparison line, `HeatMapGrid`
  - [ ] 12.2 `StatCard`s (average, change vs previous, highest station), `AttentionCard`, `RecommendationCard` from threshold rule
  - [ ] 12.3 `PDFReportRenderer` (A4 `ReportPage`) + Kongsi share sheet
  - [ ] 12.4 Tests: `InsightsViewModel` statistics and threshold card

- [ ] 13. Alerts screen _(R10)_
  - [ ] 13.1 `AlertsView`: severity chips, `AlertCard` with severity bar, time, primary action, Abaikan
  - [ ] 13.2 Primary actions execute directly (returnHome, retrySample, showOnMap)

- [ ] 14. Power _(R11)_
  - [ ] 14.1 `PowerView` sheet: `BatteryRing`, charge rate, `SolarBars` from session history, `RuntimeCard` with stations-remaining estimate
  - [ ] 14.2 `ConsumptionList` from `PowerBreakdown`; toggles for auto-return (editable threshold), autonomous, power save → `RoverCommand`

- [ ] 15. Rover model in AR — Reality Composer integration _(R5)_
  - [ ] 15.1 Add `docs/reality-composer-contract.md` listing every notification identifier in both directions (see design.md); this is the hand-off document for the student building the model on iPad
  - [ ] 15.2 Add a placeholder `Resources/Rover.reality` (a simple box rover with the same object names and behaviours) so the app builds before the real model arrives
  - [ ] 15.3 `RoverARView` (`UIViewRepresentable` → `ARView`): load `Rover.reality`, horizontal-plane anchor, coaching overlay, `NSCameraUsageDescription`
  - [ ] 15.4 Observe `RealityKit.NotifyAction` → `RoverComponent` → `ComponentInfoCard`
  - [ ] 15.5 Group chips and scale toggle post `RealityKit.NotificationTrigger` (`showAll`, `showPensampel`, `showElektronik`, `showPropulsi`, `scaleReal`, `scaleTabletop`)
  - [ ] 15.6 "Main demo pensampelan": post `playSampling`; observe `samplingStep1…6` and drive the shared `StepBar`
  - [ ] 15.7 Simulator fallback: `cameraMode = .nonAR`, world anchor, orbit/pinch gestures; same notifications
  - [ ] 15.8 Tests: identifier ↔ `RoverComponent` mapping, trigger IDs match the contract file

- [ ] 16. Settings _(R12)_
  - [ ] 16.1 `SettingsView` sheet with the nine sections and summary lines
  - [ ] 16.2 Language switch without restart; iCloud sync toggle (CloudKit via SwiftData); Tentang page

- [ ] 17. Showcase mode _(R14)_
  - [ ] 17.1 `ShowcaseCoordinator` with the four-step sequence, 5× simulated client, tab driving, exit
  - [ ] 17.2 `ShowcaseOverlay` with caption (BM/EN) and "Seterusnya"; long-press on Splash logo to start
  - [ ] 17.3 Time the full run on device — must be under 3 minutes with no network

- [ ] 18. Polish & QA
  - [ ] 18.1 Landscape layouts for Live Map, Samples and Insights
  - [ ] 18.2 Accessibility pass: labels, Dynamic Type, non-colour status cues
  - [ ] 18.3 Full demo run at 5× in the simulator: all 12 screens reachable, at least one alert per severity, CSV + PDF export succeed
  - [ ] 18.4 Update README with build steps and demo-mode instructions
