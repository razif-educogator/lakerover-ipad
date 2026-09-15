import SwiftUI

struct MissionProgressView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var confirmReturn = false

    private var mission: Mission? { env.runtime.activeMission }
    private var telemetry: Telemetry { env.telemetry.latest }
    private var stations: [Station] { mission?.orderedStations ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let mission {
                    ProgressHeader(
                        completed: mission.completedStationCount,
                        total: mission.stations.count,
                        estimatedFinish: estimatedFinish,
                        remainingDistanceM: remainingDistance
                    )
                    .cardStyle()

                    StationTimeline(
                        stations: stations,
                        currentIndex: telemetry.currentStationIndex
                    ) { station in
                        env.router.sheet = .stationDetail(station.id)
                    }
                    .cardStyle(padding: 6)

                    HStack(spacing: 12) {
                        SecondaryButton(telemetry.isPaused ? "Sambung misi" : "Jeda misi") {
                            env.send(telemetry.isPaused ? .resume : .pause)
                        }
                        DestructiveButton("Pulang ke jeti") { confirmReturn = true }
                    }
                } else {
                    Text("Tiada misi aktif").foregroundStyle(.secondary)
                }
            }
            .padding(Theme.gutter)
        }
        .background(Theme.screenBackground)
        .navigationTitle(mission.map { "Misi \($0.lakeName)" } ?? Localization.t("Misi"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    env.router.missionPath = [.roverModel]
                } label: {
                    Label("Model AR", systemImage: "cube.transparent")
                }
            }
            RoverToolbar()
        }
        .confirmationDialog(
            "Pulang ke jeti sekarang?",
            isPresented: $confirmReturn,
            titleVisibility: .visible
        ) {
            Button("Pulang ke jeti", role: .destructive) { env.send(.returnHome) }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Stesen yang belum disampel akan ditinggalkan.")
        }
    }

    /// Remaining route from the current station to the last one.
    private var remainingDistance: Double {
        let pending = stations.filter { $0.status == .waiting || $0.status == .inProgress }
        guard let first = pending.first else { return 0 }
        var total = env.telemetry.hasData ? Geo.distance(telemetry.coordinate, first.coordinate) : 0
        total += zip(pending, pending.dropFirst()).reduce(0) { $0 + Geo.distance($1.0.coordinate, $1.1.coordinate) }
        return total
    }

    private var estimatedFinish: Date? {
        let pending = stations.count { $0.status == .waiting || $0.status == .inProgress }
        guard pending > 0 else { return nil }
        let samplingSeconds = Double(pending) * 45
        let travelSeconds = remainingDistance / 1.2
        return Date().addingTimeInterval(samplingSeconds + travelSeconds)
    }
}
