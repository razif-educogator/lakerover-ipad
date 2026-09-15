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
