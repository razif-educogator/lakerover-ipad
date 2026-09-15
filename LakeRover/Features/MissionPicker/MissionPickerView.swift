import SwiftData
import SwiftUI

struct MissionPickerView: View {
    enum Filter: String, CaseIterable {
        case all, today, completed, draft

        var label: String {
            switch self {
            case .all: Localization.t("Semua")
            case .today: Localization.t("Hari ini")
            case .completed: Localization.t("Lengkap")
            case .draft: Localization.t("Draf")
            }
        }
    }

    @Environment(AppEnvironment.self) private var env
    @Query(sort: \Mission.plannedDate) private var missions: [Mission]

    @State private var search = ""
    @State private var filter: Filter = .all
    @State private var selectedID: UUID?

    var body: some View {
        VStack(spacing: 14) {
            searchField
            ChipRow(items: Filter.allCases, label: \.label, selection: $filter)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filtered) { mission in
                        Button {
                            selectedID = mission.id
                        } label: {
                            MissionRow(
                                mission: mission,
                                weather: env.weather.summary(forLake: mission.lakeName),
                                selected: mission.id == selectedID
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 4)
            }

            VStack(spacing: 10) {
                PrimaryButton("Mula misi", enabled: selectedMission != nil) {
                    if let mission = selectedMission { start(mission) }
                }
                SecondaryButton("+ Misi baharu") {
                    env.router.missionPath = [.editor]
                }
            }
        }
        .padding(Theme.gutter)
        .background(Theme.screenBackground)
        .navigationTitle("Pilih misi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { RoverToolbar() }
        .onAppear { if selectedID == nil { selectedID = defaultSelection?.id } }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Cari tasik atau misi…", text: $search)
                .textFieldStyle(.plain)
            if !search.isEmpty {
                Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.cardBackground, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var defaultSelection: Mission? {
        filtered.first { $0.lakeName == SeedDataLoader.demoLakeName } ?? filtered.first
    }

    private var selectedMission: Mission? {
        missions.first { $0.id == selectedID }
    }

    private var filtered: [Mission] {
        missions.filter { mission in
            let matchesSearch = search.isEmpty
                || mission.lakeName.localizedCaseInsensitiveContains(search)
                || mission.name.localizedCaseInsensitiveContains(search)
            guard matchesSearch else { return false }
            switch filter {
            case .all: return true
            case .today: return Calendar.current.isDateInToday(mission.plannedDate)
            case .completed: return mission.state == .completed
            case .draft: return mission.state == .draft
            }
        }
    }

    /// R2.4: set the active mission, send the route, open Live Map.
    private func start(_ mission: Mission) {
        env.startMission(mission)
        env.router.go(.live)
    }
}
