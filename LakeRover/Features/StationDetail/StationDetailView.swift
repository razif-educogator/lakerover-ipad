import SwiftUI

struct StationDetailView: View {
    var stationID: UUID

    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Set<Parameter> = []

    private var station: Station? { env.runtime.station(id: stationID) }
    private var telemetry: Telemetry { env.telemetry.latest }

    /// R4.4 — sampling needs the rover within 10 m of the station.
    private var distanceM: Double? {
        guard let station, env.telemetry.hasData else { return nil }
        return Geo.distance(telemetry.coordinate, station.coordinate)
    }

    private var canSample: Bool {
        guard let distanceM else { return false }
        return distanceM <= 10
    }

    var body: some View {
        NavigationStack {
            Group {
                if let station {
                    content(station)
                } else {
                    Text("Stesen tidak dijumpai").foregroundStyle(.secondary)
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
        .onAppear {
            if selection.isEmpty {
                selection = Set(station?.targetParameters ?? [.turbidity, .temperature, .pH, .dissolvedOxygen])
            }
        }
    }

    private var titleText: String {
        guard let station else { return Localization.t("Butiran stesen") }
        return "Stesen \(station.shortCode) · \(station.name)"
    }

    private func content(_ station: Station) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MiniMap(
                    stations: env.runtime.activeMission?.orderedStations ?? [station],
                    highlighted: station,
                    height: 170
                )

                Text(String(format: "%.4f, %.4f", station.latitude, station.longitude))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    KeyValueRow("Kedalaman", station.depthM.map { String(format: "%.1f m", $0) } ?? "—")
                    Divider()
                    KeyValueRow("Jarak dari rover", distanceM.map { String(format: "%.0f m", $0) } ?? "—")
                    Divider()
                    KeyValueRow(
                        "Sampel terakhir",
                        station.lastSampleAt?.formatted(.dateTime.day().month(.wide).year()) ?? "Tiada rekod"
                    )
                    Divider()
                    KeyValueRow(
                        "Kekeruhan terakhir",
                        station.lastTurbidityNTU.map { String(format: "%.0f NTU", $0) } ?? "—"
                    )
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Parameter sasaran").sectionTitle()
                    ParameterChecklist(selection: $selection)
                }
                .cardStyle()

                Text("Isipadu sampel: 5.0 L · Kartrij \(String(format: "C%02d-A91", station.index + 1))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !canSample {
                    Label(reason, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(Theme.warning)
                }

                HStack(spacing: 12) {
                    PrimaryButton("Mula pensampelan", enabled: canSample) {
                        station.targetParameters = Array(selection)
                        env.send(.startSampling(stationIndex: station.index, parameters: Array(selection)))
                        dismiss()
                        env.router.pushMission(.sampling)
                    }
                    SecondaryButton("Langkau") {
                        station.status = .skipped
                        env.send(.skipStation(station.index))
                        dismiss()
                    }
                }
            }
            .padding(Theme.gutter)
        }
        .background(Theme.screenBackground)
    }

    private var reason: String {
        guard let distanceM else {
            return Localization.t("Menunggu telemetri rover.")
        }
        return String(format: "Rover %.0f m dari stesen — pensampelan bermula dalam jarak 10 m.", distanceM)
    }
}
