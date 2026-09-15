import SwiftUI

struct SamplesView: View {
    enum Filter: String, CaseIterable {
        case all, done, inProgress, pending

        func label(count: Int) -> String {
            let base: String
            switch self {
            case .all: base = String(localized: "Semua")
            case .done: base = String(localized: "Selesai")
            case .inProgress: base = String(localized: "Diproses")
            case .pending: base = String(localized: "Belum")
            }
            return "\(base) (\(count))"
        }
    }

    /// A sample, or a station that has not produced one yet.
    private enum Row: Identifiable {
        case sample(Sample)
        case pending(Station)

        var id: String {
            switch self {
            case .sample(let s): "sample-\(s.id.uuidString)"
            case .pending(let s): "pending-\(s.id.uuidString)"
            }
        }
    }

    @Environment(AppEnvironment.self) private var env
    @State private var filter: Filter = .all
    @State private var selectedID: UUID?
    @State private var csvURL: URL?

    private var mission: Mission? { env.runtime.activeMission }
    private var samples: [Sample] { mission?.orderedSamples ?? [] }

    private var selectedSample: Sample? {
        samples.first { $0.id == selectedID } ?? samples.last
    }

    var body: some View {
        NavigationSplitView {
            list
                .navigationTitle("Sampel")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { RoverToolbar() }
        } detail: {
            if let sample = selectedSample {
                SampleDetailPane(sample: sample, csvURL: csvURL) {
                    env.router.focusOnMap(stationID: sample.station?.id)
                }
                .navigationTitle(sample.code)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView(
                    "Tiada sampel lagi",
                    systemImage: "testtube.2",
                    description: Text("Sampel akan muncul di sini sebaik sahaja stesen pertama selesai.")
                )
            }
        }
        .task(id: samples.count) { refreshCSV() }
    }

    private var list: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Filter.allCases, id: \.self) { option in
                        Chip(title: option.label(count: count(for: option)), selected: filter == option) {
                            filter = option
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.gutter)

            List(rows, selection: $selectedID) { row in
                switch row {
                case .sample(let sample):
                    Button { selectedID = sample.id } label: {
                        SampleRow(sample: sample, selected: sample.id == selectedID)
                    }
                    .buttonStyle(.plain)
                case .pending(let station):
                    PendingSampleRow(station: station)
                }
            }
            .listStyle(.plain)
        }
        .background(Theme.screenBackground)
    }

    private var rows: [Row] {
        var result: [Row] = []
        let matching = samples.filter { matches(filter, sample: $0) }
        result += matching.map(Row.sample)
        if filter == .all || filter == .pending {
            let pending = (mission?.orderedStations ?? []).filter { station in
                station.status != .done && !samples.contains { $0.station?.id == station.id }
            }
            result += pending.map(Row.pending)
        }
        return result
    }

    private func matches(_ filter: Filter, sample: Sample) -> Bool {
        switch filter {
        case .all: true
        case .done: sample.status == .done
        case .inProgress: sample.status == .inProgress
        case .pending: false
        }
    }

    private func count(for filter: Filter) -> Int {
        switch filter {
        case .all: samples.count
        case .done: samples.count { $0.status == .done }
        case .inProgress: samples.count { $0.status == .inProgress }
        case .pending:
            (mission?.orderedStations ?? []).count { station in
                station.status != .done && !samples.contains { $0.station?.id == station.id }
            }
        }
    }

    private func refreshCSV() {
        guard let mission, !samples.isEmpty else { csvURL = nil; return }
        csvURL = try? CSVExporter.write(samples: samples, missionName: mission.lakeName)
    }
}

struct SampleRow: View {
    var sample: Sample
    var selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(sample.code)
                    .font(.subheadline.weight(.semibold))
                Text("\(sample.station?.shortCode ?? "—") · \(sample.takenAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            Circle()
                .fill(sample.status.tint)
                .frame(width: 8, height: 8)
            Text(sample.status.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            selected ? Theme.accent.opacity(0.12) : Color.clear,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }
}

struct PendingSampleRow: View {
    var station: Station

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("—").font(.subheadline.weight(.semibold))
                Text("\(station.shortCode) · \(station.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            Text(station.status.label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }
}
