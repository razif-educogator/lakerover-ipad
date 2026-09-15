# Tech — LakeRover iPad app

- **Platform:** iPadOS 18+, iPad only (no iPhone target). Portrait and landscape both supported; wireframes are portrait 3:4.
- **Language / UI:** Swift 6, SwiftUI. No UIKit unless SwiftUI has no equivalent.
- **Persistence:** SwiftData for missions, stations, samples, alerts and settings. No CoreData, no third-party ORMs.
- **Map:** MapKit (`Map` in SwiftUI) with `MapPolyline` for the route and custom `Annotation` views for stations and the rover. Satellite/standard toggle via `MapStyle`. Depth and turbidity layers are drawn as `MapPolygon`/`MapCircle` overlays from local data.
- **AR:** RealityKit + ARKit via `ARView` (`UIViewRepresentable`). The rover model, animations and tap behaviours are authored in **Reality Composer on iPad** and shipped as `Resources/Rover.reality`; the app talks to it only through `RealityKit.NotifyAction` / `RealityKit.NotificationTrigger` notifications (contract in `docs/reality-composer-contract.md`). No 3D code in the app. `FeatureFlags.arEnabled` only chooses AR vs non-AR camera (Simulator).
- **Charts:** Swift Charts.
- **Rover link:** a `RoverClient` protocol with two implementations — `SimulatedRoverClient` (demo mode, always available) and `NetworkRoverClient` (WebSocket over local Wi-Fi / 4G, JSON telemetry). The UI never talks to a concrete client directly.
- **Cartridge tags:** Core NFC (`NFCTagReaderSession`) behind a protocol so it can be mocked in the simulator.
- **Export:** CSV via `FileDocument` + `ShareLink`; PDF report via `ImageRenderer`.
- **Architecture:** MVVM with `@Observable` view models. One view model per screen. Services (rover client, NFC, export, telemetry store) are injected through the SwiftUI environment.
- **Concurrency:** Swift concurrency (`async/await`, `AsyncStream` for telemetry). No Combine.
- **Testing:** Swift Testing (`@Test`) for models, view models and the simulated client. Snapshot or UI tests are optional.
- **Dependencies:** none. Standard Apple frameworks only.
- **Tooling:** Xcode 16+. Project generated with XcodeGen from `project.yml` so the repo stays diff-friendly; run `xcodegen generate` after cloning.

## Conventions
- Strings: Bahasa Malaysia keys in `Localizable.xcstrings`, English translations included. Never hard-code UI text.
- Units: metres, litres, °C, NTU, mg/L, W, %. Format with `Measurement` / `FormatStyle`.
- Dates in `en_MY` locale, 12-hour clock as in the wireframes.
- Accessibility: every custom control has a label; Dynamic Type supported; colours are never the only status signal (use icon + text).
- Colours: single accent `Color("LakeBlue")`; status colours `success`, `warning`, `critical` defined once in `Theme.swift`.
