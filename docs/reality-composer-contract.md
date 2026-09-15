# Reality Composer ↔ app contract

File: `Resources/Rover.reality` (export from Reality Composer on iPad as **Reality File**, not USDZ).
Object names in the scene: `AntenaGPS`, `PanelSolar`, `Kamera360`, `Pensampel`, `Pendorong`, `Badan`, `Botol`, `Kartrij`, `Pam`.

## Model → app (Behavior: … → Notify)
| Identifier | When |
|---|---|
| `antenaGPS` | Tap on AntenaGPS |
| `panelSolar` | Tap on PanelSolar |
| `kamera360` | Tap on Kamera360 |
| `pensampel` | Tap on Pensampel |
| `pendorong` | Tap on Pendorong |
| `samplingStep1` … `samplingStep6` | at each step of the sampling animation (Tiba, Daftar, Sampel, Tag, Simpan, Gerak) |

## App → model (Behavior: Trigger Notification → …)
| Identifier | Expected action |
|---|---|
| `showAll` | show every component |
| `showPensampel` | show Pam, Kartrij, Botol, Pensampel; hide the rest (Badan stays) |
| `showElektronik` | show AntenaGPS, Kamera360, PanelSolar |
| `showPropulsi` | show Pendorong |
| `playSampling` | animate Pam → Kartrij → Botol, posting `samplingStep1…6` along the way |
| `scaleReal` / `scaleTabletop` | scale 1:1 / 1:5 |

Identifiers are case-sensitive and must match exactly.

## Placeholder until the real model arrives

`Resources/Rover.reality` is **not** in the repo yet. Until it is, the app builds an
equivalent stand-in in code — `PlaceholderRoverBuilder` — using the same object names as
the table above, and `RoverModelViewModel` plays the model's half of the contract
(group show/hide, scale, and the `samplingStep1…6` sequence for `playSampling`).

To swap in the real model:

1. Export from Reality Composer on iPad as **Reality File** → `Rover.reality`.
2. Drop it into `LakeRover/Resources/`.
3. `xcodegen generate` and build.

No code changes. `RoverNotificationBridge.hasRealityFile` flips to `true`, the placeholder
and its stand-in behaviours switch themselves off, and the app starts listening to the real
scene instead.

## Where the app runs which view

| Environment | View | Why |
|---|---|---|
| iPad hardware | `RoverARView` (`ARView`, horizontal plane, coaching overlay) | Full AR |
| Simulator | `RoverDiagramView` (2D exploded diagram) | No AR camera; identical notifications |

`FeatureFlags.arEnabled` is what chooses between them. Both post and observe exactly the
identifiers listed above, so the Showcase run behaves the same in either place.
