import MapKit
import SwiftUI

struct LiveMapView: View {
    @Environment(AppEnvironment.self) private var env

    @State private var camera: MapCameraPosition = .region(LiveMapView.defaultRegion)
    @State private var layer: MapLayer = .satellite
    @State private var follow = true
    @State private var confirmSkip = false

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 5.0112, longitude: 100.9714),
        latitudinalMeters: 700,
        longitudinalMeters: 700
    )

    private var telemetry: Telemetry { env.telemetry.latest }
    private var mission: Mission? { env.runtime.activeMission }
    private var stations: [Station] { mission?.orderedStations ?? [] }

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
                    HStack(spacing: 6) {
                        Circle()
                            .fill(env.telemetry.hasData ? Theme.success : Theme.waiting)
                            .frame(width: 8, height: 8)
                        Text(env.telemetry.hasData ? "Live" : "Tiada telemetri")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                RoverToolbar()
            }
            .onChange(of: Int(telemetry.uptime)) { _, _ in recentreIfFollowing() }
            .onChange(of: env.router.mapFocusStationID) { _, id in focus(on: id) }
            .onAppear { focus(on: env.router.mapFocusStationID) }
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

    // MARK: Overlays

    private var overlays: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                RoverStatusPanel(telemetry: telemetry)
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
                    onRecentre: {
                        follow = true
                        recentre(on: telemetry.coordinate)
                    },
                    onCamera: { env.router.sheet = .camera },
                    onStop: {
                        env.send(telemetry.isStopped ? .resumeAfterStop : .emergencyStop)
                    }
                )
            }
            .padding(.horizontal, Theme.gutter)

            if telemetry.isStopped {
                stopBanner
                    .padding(.horizontal, Theme.gutter)
                    .padding(.top, Theme.tight)
            }

            NextStationCard(
                station: currentStation,
                distanceM: telemetry.distanceToStationM,
                etaSeconds: telemetry.etaToStationS,
                samplingInProgress: telemetry.sampling != nil,
                onDetails: {
                    if let id = currentStation?.id { env.router.sheet = .stationDetail(id) }
                },
                onSkip: { confirmSkip = true }
            )
            .padding(Theme.gutter)
        }
    }

    private var stopBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.raised.fill")
            Text("Berhenti kecemasan aktif — rover menahan kedudukan.")
                .font(.footnote.weight(.medium))
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
