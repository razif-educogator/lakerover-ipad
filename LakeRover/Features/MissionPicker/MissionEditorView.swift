import MapKit
import SwiftUI

/// R2.5 — create a mission: name, lake, date, tap the map to add stations, drag to reorder.
struct MissionEditorView: View {
    struct DraftStation: Identifiable, Hashable {
        let id = UUID()
        var name: String
        var latitude: Double
        var longitude: Double
    }

    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var lakeName = ""
    @State private var date = Date()
    @State private var stations: [DraftStation] = []
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 5.0112, longitude: 100.9714),
            latitudinalMeters: 1200,
            longitudinalMeters: 1200
        )
    )

    var body: some View {
        Form {
            Section("Butiran misi") {
                TextField("Nama misi", text: $name)
                TextField("Nama tasik", text: $lakeName)
                DatePicker("Tarikh", selection: $date, displayedComponents: .date)
            }

            Section("Stesen") {
                MapReader { proxy in
                    Map(position: $camera) {
                        if stations.count > 1 {
                            MapPolyline(coordinates: stations.map(\.coordinate))
                                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                        }
                        ForEach(Array(stations.enumerated()), id: \.element.id) { index, station in
                            Annotation(station.name, coordinate: station.coordinate) {
                                Text("\(index + 1)")
                                    .font(.caption2.weight(.bold))
                                    .frame(width: 24, height: 24)
                                    .background(Theme.accent, in: Circle())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .mapStyle(.hybrid)
                    .frame(height: 260)
                    .onTapGesture { point in
                        if let coordinate = proxy.convert(point, from: .local) {
                            addStation(at: coordinate)
                        }
                    }
                }
                .listRowInsets(EdgeInsets())

                Text("Ketik peta untuk menambah stesen. Seret untuk menukar susunan.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach($stations) { $station in
                    HStack {
                        Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary)
                        TextField("Nama stesen", text: $station.name)
                        Spacer()
                        Text(String(format: "%.4f, %.4f", station.latitude, station.longitude))
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                .onMove { source, destination in
                    stations.move(fromOffsets: source, toOffset: destination)
                }
                .onDelete { stations.remove(atOffsets: $0) }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Misi baharu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Simpan sebagai draf") { save() }
                    .disabled(stations.isEmpty || lakeName.isEmpty)
            }
        }
    }

    private func addStation(at coordinate: CLLocationCoordinate2D) {
        stations.append(
            DraftStation(
                name: "Stesen \(stations.count + 1)",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        )
    }

    private func save() {
        let mission = Mission(
            name: name.isEmpty ? "Misi \(lakeName)" : name,
            lakeName: lakeName,
            plannedDate: date,
            state: .draft,
            routeLengthM: routeLength
        )
        mission.stations = stations.enumerated().map { index, draft in
            Station(
                index: index,
                name: draft.name,
                zone: draft.name,
                latitude: draft.latitude,
                longitude: draft.longitude,
                depthM: 3
            )
        }
        env.context.insert(mission)
        try? env.context.save()
        env.router.missionPath = []
        dismiss()
    }

    private var routeLength: Double {
        guard stations.count > 1 else { return 0 }
        return zip(stations, stations.dropFirst())
            .reduce(0) { $0 + Geo.distance($1.0.coordinate, $1.1.coordinate) }
    }
}

private extension MissionEditorView.DraftStation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
