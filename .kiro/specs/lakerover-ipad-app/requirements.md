# Requirements — LakeRover iPad app (v1)

## Introduction

LakeRover v1 is the iPad app an operator uses to run a water-sampling mission with the LakeRover rover, from choosing a lake to sharing a report. v1 must work end to end in **demo mode** (simulated rover) and be ready to swap in the real rover link without UI changes. Screens and navigation follow `docs/wireframes/storyboard-v1.png` (12 screens).

Glossary
- **Mission** — a planned route on one lake made of ordered **stations**.
- **Station** — a GPS point where the rover stops to take one **sample**.
- **Sample** — one cartridge filled at a station, with sensor readings (turbidity NTU, temperature °C, pH, dissolved oxygen mg/L) and an RFID/NFC tag ID.
- **Telemetry** — live rover data: position, heading, speed, battery %, solar W, link quality, pump flow, fill volume.
- **Operator** — the signed-in-free user of the app (no accounts in v1).

## Requirements

### R1 — Splash & rover connection
**User story:** As an operator, I want to see whether the rover is connected before I start, so I can fix the link or fall back to demo mode.
1. WHEN the app launches THEN the system SHALL show the LakeRover logo, tagline, a connection card and a "Mula" button.
2. WHEN a rover is reachable THEN the connection card SHALL show rover name, link type, battery % and GPS satellite count, updated at least every 5 s.
3. WHEN no rover is reachable within 10 s THEN the system SHALL show "Rover tidak dijumpai" and keep the "Cuba mod demo" link enabled.
4. WHEN the operator taps "Cuba mod demo" THEN the system SHALL start `SimulatedRoverClient`, mark the session as demo, and show a persistent "Demo" badge in every screen header.
5. WHEN the operator taps "Mula" THEN the system SHALL navigate to Mission Picker.

### R2 — Mission picker
**User story:** As an operator, I want to choose a lake mission quickly, so I can start on time.
1. WHEN Mission Picker opens THEN the system SHALL list all missions with lake name, thumbnail, station count, route length, planned date and current weather summary.
2. WHEN the operator types in the search field THEN the list SHALL filter by lake or mission name as they type.
3. WHEN the operator selects a filter chip (Semua / Hari ini / Lengkap / Draf) THEN the list SHALL show only missions in that state.
4. WHEN the operator selects a mission and taps "Mula misi" THEN the system SHALL set it as the active mission, send the route to the rover client, and open Live Map.
5. WHEN the operator taps "Misi baharu" THEN the system SHALL open a form to enter lake name, date and stations (tap on a map to add a station; reorder by drag), and save the mission as Draf.
6. IF weather data is unavailable THEN the mission row SHALL show "Cuaca tidak tersedia" instead of a weather badge.

### R3 — Live map
**User story:** As an operator, I want a real-time map of the rover, so I know where it is and what it is doing.
1. WHEN Live Map is shown THEN the system SHALL render the lake, the route as a dashed polyline, every station as a numbered marker, and the rover as a heading-oriented marker.
2. WHILE telemetry is streaming THE rover marker SHALL update its position and heading at least once per second.
3. WHEN Live Map is shown THEN the status panel SHALL show speed (m/s), heading (° + compass point), battery %, solar W and link quality.
4. WHEN a station is completed THEN its marker SHALL change to the success style; the current target station SHALL use the highlighted style.
5. WHEN the operator selects a map layer chip (Satelit / Kedalaman / Kekeruhan) THEN the map SHALL switch to that layer; Kedalaman and Kekeruhan render overlays from the mission's stored data.
6. WHEN the operator taps the recentre control THEN the map SHALL centre on the rover; the camera control SHALL open the live camera sheet.
7. WHEN the operator taps the red "Berhenti" control THEN the system SHALL send an emergency stop to the rover within 200 ms, show a confirmation banner, and require a deliberate "Sambung semula" action to resume.
8. WHEN Live Map is shown THEN the "next station" card SHALL show station name, zone, distance and ETA, with "Butiran" (opens Station Detail) and "Langkau" (skips the station after confirmation).

### R4 — Station detail
**User story:** As an operator, I want to check a station before sampling, so that I don't waste a cartridge.
1. WHEN Station Detail opens THEN the system SHALL show a mini map, coordinates, depth, distance from rover, last sample date and last turbidity reading.
2. WHEN Station Detail opens THEN the system SHALL list the target parameters with checkboxes preselected from the mission template.
3. WHEN the operator taps "Mula pensampelan" THEN the system SHALL send the sampling command with the selected parameters and open the Sampling screen.
4. IF the rover is farther than 10 m from the station THEN the "Mula pensampelan" button SHALL be disabled with the reason shown.

### R5 — Rover model in AR (Reality Composer)
**User story:** As a student presenting to judges, I want to place a life-size LakeRover on the table in AR and tap its parts to explain how it works, so the idea feels real before the hardware is finished.

The 3D model, its animations and its tap behaviours are authored by the team in **Reality Composer on iPad** and shipped as `Resources/Rover.reality`. The app only loads the file and exchanges notifications with it — no 3D code lives in the app.
1. WHEN Rover Model opens THEN the system SHALL load `Rover.reality` into an `ARView`, anchor it to the first detected horizontal plane, and show a coaching overlay until a plane is found.
2. WHEN the operator taps a component in the AR scene (identifiers `antenaGPS`, `panelSolar`, `kamera360`, `pensampel`, `pendorong`) THEN the Reality file SHALL play its own emphasis animation and post a `RealityKit.NotifyAction` notification, and the app SHALL show a `ComponentInfoCard` with that component's name, role and a 1–2 sentence explanation.
3. WHEN the operator selects a group chip (Keseluruhan / Pensampel / Elektronik / Propulsi) THEN the app SHALL post a `RealityKit.NotificationTrigger` with identifier `showAll` / `showPensampel` / `showElektronik` / `showPropulsi`, and the Reality file SHALL show only that group's components.
4. WHEN the operator taps "Main demo pensampelan" THEN the app SHALL post the `playSampling` trigger and the Reality file SHALL animate the pump → cartridge → bottle sequence; the app SHALL mirror the sequence in the `StepBar` so screen 7 and the AR model tell the same story.
5. WHEN the operator taps "Skala sebenar" THEN the model SHALL toggle between tabletop scale (1:5) and real scale (1:1).
6. IF the device has no AR camera (Simulator) THEN the system SHALL fall back to a non-AR 3D view with orbit and pinch-zoom, using the same Reality file and the same notifications.
7. THE identifiers above SHALL be the contract between the Reality Composer project and the app, listed in `docs/reality-composer-contract.md`, so the model can be improved without touching code.

### R6 — Mission progress
**User story:** As an operator, I want to see mission progress by station, so I can estimate when we finish.
1. WHEN Mission Progress opens THEN the system SHALL show completed/total stations, a percentage bar, estimated completion time and remaining distance.
2. WHEN Mission Progress opens THEN the system SHALL list every station with number, name, timestamp and status (Selesai / Sedang diproses / Menunggu / Dilangkau), current station highlighted.
3. WHEN the operator taps "Jeda misi" THEN the rover SHALL hold position and the button SHALL become "Sambung misi".
4. WHEN the operator taps "Pulang ke jeti" THEN the system SHALL ask for confirmation, then command return-to-home.

### R7 — Sampling process (live)
**User story:** As an operator, I want to watch the sampling process live, so I can intervene if something goes wrong.
1. WHEN Sampling opens THEN the system SHALL show the six-step bar (Tiba, Daftar, Sampel, Tag, Simpan, Gerak) with the current step highlighted, driven by telemetry.
2. WHILE sampling is running THE flow diagram SHALL animate pump → cartridge → bottle and show pump flow (L/min), cartridge ID and elapsed time.
3. WHILE sampling is running THE live data panel SHALL show turbidity, temperature, pH and DO updated at least every 2 s.
4. WHILE sampling is running THE fill progress SHALL show filled/target volume and an estimated time to finish.
5. WHEN the "Tag" step is reached THEN the system SHALL read the cartridge tag via the NFC reader (or a simulated tag in demo mode) and attach the ID to the sample record.
6. WHEN the operator taps "Hentikan" THEN the system SHALL stop the pump, mark the sample as "Dibatalkan" and return to Live Map.
7. WHEN the operator taps "Ulang sampel" THEN the system SHALL discard the current readings and restart from the Sampel step.
8. WHEN the Gerak step completes THEN the system SHALL save the sample record and navigate back to Live Map.

### R8 — Sample records
**User story:** As a teacher, I want every sample recorded with its readings, so the data can be used in class.
1. WHEN Samples opens THEN the system SHALL list every sample of the active mission with ID, station, time and status, filterable by status chips.
2. WHEN the operator selects a sample THEN the detail pane SHALL show location, time, volume, tag ID, status and a sensor table (NTU, °C, pH, DO).
3. WHEN the operator edits the "Nota pelajar" field THEN the note SHALL be saved to the sample on change.
4. WHEN the operator taps "Lihat di peta" THEN Live Map SHALL open centred on that station.
5. WHEN the operator taps "Eksport CSV" THEN the system SHALL generate a CSV of all samples in the mission (one row per sample, UTF-8, header row) and present a share sheet.

### R9 — Data & insight
**User story:** As a teacher, I want to see trends and problem zones, so we can turn data into action.
1. WHEN Insights opens THEN the system SHALL show a line chart of the selected parameter (Kekeruhan / Suhu / pH / DO) across stations for the selected range (Misi ini / 30 hari), with the previous mission as a faint comparison line when available.
2. WHEN Insights opens THEN the system SHALL show a lake heat map grid coloured by the selected parameter's latest value near each station.
3. WHEN Insights opens THEN the system SHALL show mission average, change versus the previous mission, and the station with the highest value.
4. IF any station's turbidity exceeds the configured threshold (default 15 NTU) THEN the system SHALL show a "Perhatian" card naming the zone and a "Cadangan tindakan" card with a suggested next step.
5. WHEN the operator taps "Jana laporan PDF" THEN the system SHALL render a one-page PDF (mission summary, chart, heat map, sample table) and present a share sheet.

### R10 — Alerts
**User story:** As an operator, I want alerts that tell me what to do, not just what happened.
1. WHEN telemetry meets an alert rule (battery < 20 %, pump flow < 0.8 L/min for 10 s, obstacle detected, link lost > 15 s, water ingress) THEN the system SHALL create an alert with severity (Kritikal / Amaran / Maklumat), title, description, time and a primary action.
2. WHEN Alerts opens THEN the system SHALL list alerts newest first, filterable by severity chips, with the unread count shown as a badge on the Amaran tab.
3. WHEN the operator taps an alert's primary action (e.g. "Pulang ke jeti", "Ulang sampel", "Lihat di peta") THEN the system SHALL perform that action directly from the list.
4. WHEN the operator taps "Abaikan" THEN the alert SHALL be marked dismissed and hidden from the default filter.
5. WHEN a Kritikal alert is created THEN the system SHALL also show a top banner on whatever screen is open.

### R11 — Power management
**User story:** As an operator, I want to know how long the rover can keep going, so I can plan the mission.
1. WHEN Power opens THEN the system SHALL show battery % (ring), charge/discharge rate, solar output W and a bar chart of solar generation for the current session.
2. WHEN Power opens THEN the system SHALL show estimated remaining operating time and how many stations that covers at the current average consumption.
3. WHEN Power opens THEN the system SHALL show power consumption by subsystem (thruster, pump, 4G link, computer, camera & sensors).
4. WHEN the operator toggles "Pulang automatik jika bateri < 25 %" THEN the threshold SHALL be editable and sent to the rover; the same for "Mod operasi autonomi" and "Mod jimat kuasa".

### R12 — Settings
1. WHEN Settings opens THEN the system SHALL show sections: Rover & sambungan, Misi & stesen, Sensor & kalibrasi, Tag kartrij, Data & awan, Notifikasi, Peta, Bahasa, Tentang — each with a summary line as in the wireframe.
2. WHEN the operator changes the language THEN the UI SHALL switch between Bahasa Malaysia and English without restart.
3. WHEN the operator enables "Selaras ke iCloud / Drive" THEN missions and samples SHALL sync via iCloud (CloudKit through SwiftData) — Drive export is via the share sheet only.

### R13 — Navigation & demo mode
1. THE app SHALL use a five-tab bar (Live, Misi, Sampel, Data, Amaran) on every main screen, with Tenaga and Tetapan reachable from header icons.
2. WHILE demo mode is active THE `SimulatedRoverClient` SHALL play a scripted mission on Tasik Cenderoh (6 stations) that completes in about 8 minutes at 1× speed, with a hidden 5× speed option for rehearsal, and SHALL raise at least one alert of each severity during the run.
3. THE app SHALL persist missions, stations, samples, alerts and settings with SwiftData so a force-quit loses nothing except in-flight telemetry.

### R14 — Showcase mode (idea competition)
**User story:** As a judge with three minutes, I want to see the whole idea — problem, rover, data, action — without anyone fiddling with settings.
1. WHEN the operator long-presses the logo on Splash THEN the system SHALL start Showcase mode: demo rover at 5×, Tasik Cenderoh mission pre-selected, and a guided sequence Live Map → Sampling → AR model → Insights with a "Seterusnya" button on each step.
2. WHILE Showcase mode is active THE system SHALL display a one-line caption per step explaining what the judge is looking at (BM and EN).
3. WHEN Showcase mode reaches Insights THEN the system SHALL end on the "Cadangan tindakan" card and the PDF report, closing the "Dari Tasik ke Data, Dari Data ke Tindakan" loop.
4. THE full Showcase run SHALL take under 3 minutes and require no network.

## Non-functional
- iPadOS 18+, iPad only, portrait and landscape.
- Launch to Splash in < 2 s on iPad (10th gen).
- All screens usable offline; weather and sync degrade gracefully.
- Bahasa Malaysia default, English available; strings in `Localizable.xcstrings`.
- No third-party dependencies.
- Unit tests for models, view models, alert rules, CSV export and the simulated client.
