import MapKit
import SwiftUI

struct LiveMapView: View {
    @Environment(AppEnvironment.self) private var env

    @State private var camera: MapCameraPosition = .region(LiveMapView.defaultRegion)
    @State private var layer: MapLayer = .satellite
    @State private var follow = true
    @State private var confirmSkip = false

    /// Only used before a mission's stations are known — the real framing is computed from
    /// the station coordinates by `region(fitting:)`.
    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.9546, longitude: 100.9503),
        latitudinalMeters: 3000,
        longitudinalMeters: 3000
    )

    /// Bounding region of a set of coordinates, with headroom so pins are not on the edge.
    private static func region(fitting coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        let valid = coordinates.filter { CLLocationCoordinate2DIsValid($0) && $0.latitude != 0 }
        guard !valid.isEmpty else { return nil }
        let latitudes = valid.map(\.latitude)
        let longitudes = valid.map(\.longitude)
        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max()
        else { return nil }

        let padding = 1.45
        let minimumSpan = 0.004 // ~440 m, so a single station does not zoom to the ground
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * padding, minimumSpan),
                longitudeDelta: max((maxLon - minLon) * padding, minimumSpan)
            )
        )
    }

    private var telemetry: Telemetry { env.telemetry.latest }
    private var mission: Mission? { env.runtime.activeMission }
    private var stations: [Station] { mission?.orderedStations ?? [] }

    /// Reads the app-wide seed weather, the same value the weather alert uses.
    private var weather: WeatherSummary? { env.currentWeather }

    /// Stations of the return trip, in the order the rover retraces them.
    private var returnLeg: [Station] {
        guard telemetry.isReturning, let from = telemetry.returnFromStationIndex else { return [] }
        return stations
            .filter { $0.index <= from }
            .sorted { $0.index > $1.index }
    }

    private var currentStation: Station? {
        guard let index = telemetry.currentStationIndex else {
            return stations.first { $0.status == .waiting }
        }
        return stations.first { $0.index == index }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                map
                    .ignoresSafeArea(edges: .bottom)

                if mission == nil {
                    noMissionOverlay
                }

                overlays
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    liveIndicator
                }
                RoverToolbar()
            }
            .onChange(of: Int(telemetry.uptime)) { _, _ in recentreIfFollowing() }
            .onChange(of: env.router.mapFocusStationID) { _, id in focus(on: id) }
            // Refit once the mission's stations exist — the Live tab can render first.
            .onChange(of: mission?.id) { _, _ in fitMission() }
            .onAppear {
                if env.router.mapFocusStationID != nil {
                    focus(on: env.router.mapFocusStationID)
                } else {
                    fitMission()
                }
            }
            .confirmationDialog(
                "Langkau stesen ini?",
                isPresented: $confirmSkip,
                titleVisibility: .visible
            ) {
                Button("Langkau", role: .destructive) {
                    if let index = currentStation?.index {
                        currentStation?.status = .skipped
                        env.send(.skipStation(index))
                    }
                }
                Button("Batal", role: .cancel) {}
            } message: {
                Text("Stesen akan ditanda sebagai dilangkau dan rover terus ke stesen berikutnya.")
            }
        }
    }

    // MARK: Map

    private var map: some View {
        Map(position: $camera, interactionModes: .all) {
            if stations.count > 1 {
                MapPolyline(coordinates: stations.map(\.coordinate))
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, dash: [8, 5]))
            }

            // Return leg: the outbound route in reverse, so it stays over water. Drawn thicker,
            // amber and dotted so it reads as a different trip from the outbound dashes.
            if returnLeg.count > 1 {
                MapPolyline(coordinates: returnLeg.map(\.coordinate))
                    .stroke(
                        Theme.warning,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [1, 9])
                    )
            }

            if layer == .depth {
                ForEach(stations) { station in
                    MapCircle(center: station.coordinate, radius: 26 + (station.depthM ?? 3) * 7)
                        .foregroundStyle(Color.blue.opacity(0.14 + min(0.4, (station.depthM ?? 3) / 14)))
                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                }
            }

            if layer == .turbidity {
                ForEach(stations) { station in
                    MapCircle(center: station.coordinate, radius: 30 + (station.lastTurbidityNTU ?? 10) * 2.6)
                        .foregroundStyle(turbidityColor(station.lastTurbidityNTU ?? 10).opacity(0.32))
                        .stroke(turbidityColor(station.lastTurbidityNTU ?? 10), lineWidth: 1)
                }
            }

            ForEach(stations) { station in
                Annotation(station.name, coordinate: station.coordinate) {
                    StationAnnotationView(station: station, isCurrent: station.id == currentStation?.id)
                }
            }

            if env.telemetry.hasData {
                Annotation("LakeRover-01", coordinate: telemetry.coordinate) {
                    RoverAnnotationView(headingDeg: telemetry.headingDeg, moving: telemetry.isMoving)
                }
            }
        }
        .mapStyle(layer == .satellite ? .hybrid(elevation: .realistic) : .standard(elevation: .flat))
        .mapControlVisibility(.hidden)
    }

    /// Horizontal pill: dot then label on one line. The dot and text used to be squeezed into
    /// the toolbar's circular item container, which wrapped "Live" to "Liv/e"; the explicit
    /// capsule plus `fixedSize` makes the indicator size to its own content instead.
    private var liveIndicator: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(env.telemetry.hasData ? Theme.success : Theme.waiting)
                .frame(width: 7, height: 7)
            Text(env.telemetry.hasData ? "Live" : "Tiada telemetri")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
        .fixedSize()
    }

    // MARK: Overlays

    private var overlays: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.tight) {
                    RoverStatusPanel(telemetry: telemetry)
                    if let weather {
                        WeatherCard(summary: weather)
                    }
                }
                Spacer(minLength: 12)
                LayerChips(layer: $layer)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.top, Theme.tight)

            Spacer(minLength: 0)

            HStack(alignment: .bottom) {
                Spacer(minLength: 0)
                MapControls(
                    stopped: telemetry.isStopped,
                    onRecentre: { fitMission() },
                    onCamera: { env.router.sheet = .camera },
                    onStop: {
                        env.send(telemetry.isStopped ? .resumeAfterStop : .emergencyStop)
                    }
                )
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, Theme.tight)

            // Banner sits above the station card with spacing; both keep their full height.
            VStack(spacing: Theme.tight) {
                if telemetry.isStopped {
                    stopBanner
                }

                NextStationCard(
                    station: currentStation,
                    distanceM: telemetry.distanceToStationM,
                    etaSeconds: telemetry.etaToStationS,
                    samplingInProgress: telemetry.sampling != nil,
                    isReturning: telemetry.isReturning,
                    onDetails: {
                        if let id = currentStation?.id { env.router.sheet = .stationDetail(id) }
                    },
                    onSkip: { confirmSkip = true }
                )
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, Theme.gutter)
        }
    }

    private var stopBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.raised.fill")
            Text("Berhenti kecemasan aktif — rover menahan kedudukan.")
                .font(.footnote.weight(.medium))
                // Wrap rather than clip when the width is tight.
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button("Sambung semula") { env.send(.resumeAfterStop) }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(Theme.critical)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(.white)
        .background(Theme.critical, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }

    private var noMissionOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "map").font(.largeTitle).foregroundStyle(.secondary)
            Text("Tiada misi aktif").font(.headline)
            Text("Pilih misi dalam tab Misi untuk mula memantau rover.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            SecondaryButton("Pilih misi") { env.router.go(.misi) }
                .frame(width: 200)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
    }

    // MARK: Camera

    private var titleText: String {
        env.settings.roverName
    }

    private func recentreIfFollowing() {
        guard follow, env.telemetry.hasData else { return }
        recentre(on: telemetry.coordinate)
    }

    /// Frames the whole mission: every station visible, with padding. Used on appear and by
    /// the recentre control. Follow mode is released so the 1 Hz rover tracking cannot
    /// immediately zoom back in and undo the fit.
    private func fitMission() {
        guard let region = Self.region(fitting: stations.map(\.coordinate)) else { return }
        follow = false
        withAnimation(.easeInOut(duration: 0.6)) {
            camera = .region(region)
        }
    }

    private func recentre(on coordinate: CLLocationCoordinate2D) {
        guard CLLocationCoordinate2DIsValid(coordinate), coordinate.latitude != 0 else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            camera = .region(
                MKCoordinateRegion(center: coordinate, latitudinalMeters: 420, longitudinalMeters: 420)
            )
        }
    }

    private func focus(on id: UUID?) {
        guard let id, let station = stations.first(where: { $0.id == id }) else { return }
        follow = false
        recentre(on: station.coordinate)
        env.router.mapFocusStationID = nil
    }

    private func turbidityColor(_ ntu: Double) -> Color {
        let threshold = mission?.turbidityThresholdNTU ?? 15
        if ntu >= threshold { return Theme.critical }
        if ntu >= threshold * 0.8 { return Theme.warning }
        return Theme.success
    }
}
