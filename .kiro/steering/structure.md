# Structure

```
LakeRover/
├── project.yml                     # XcodeGen
├── LakeRover/
│   ├── App/                        # LakeRoverApp.swift, RootView, AppEnvironment, FeatureFlags
│   ├── Theme/                      # Theme.swift, Colors.xcassets, Typography
│   ├── Models/                     # SwiftData @Model types + value types
│   ├── Services/
│   │   ├── Rover/                  # RoverClient protocol, SimulatedRoverClient, NetworkRoverClient, Telemetry
│   │   ├── NFC/                    # CartridgeTagReader protocol + implementations
│   │   ├── Export/                 # CSVExporter, PDFReportRenderer
│   │   └── Alerts/                 # AlertEngine (turns telemetry into alerts)
│   ├── Features/                   # one folder per screen: View + ViewModel
│   │   ├── Splash/
│   │   ├── MissionPicker/
│   │   ├── LiveMap/
│   │   ├── StationDetail/
│   │   ├── RoverModel/             # 3D / AR
│   │   ├── MissionProgress/
│   │   ├── Sampling/
│   │   ├── Samples/
│   │   ├── Insights/
│   │   ├── Alerts/
│   │   ├── Power/
│   │   └── Settings/
│   ├── Components/                 # shared SwiftUI views (StatusPill, StepperBar, StatCard, RoverStatusPanel …)
│   ├── Resources/                  # Localizable.xcstrings, rover.usdz, seed JSON
│   └── Preview Content/
├── LakeRoverTests/
├── docs/wireframes/                # storyboard-v1.png / .html (reference)
└── .kiro/
    ├── steering/
    └── specs/lakerover-ipad-app/
```

Rules
- A feature folder contains only that screen's `View` and `ViewModel`. Anything reused twice moves to `Components/`.
- Models never import SwiftUI. Services never import SwiftUI.
- Seed data for demo mode lives in `Resources/seed/*.json` and is loaded by `SeedDataLoader` on first launch.
