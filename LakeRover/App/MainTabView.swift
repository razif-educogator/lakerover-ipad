import SwiftUI

struct MainTabView: View {
    @Environment(AppEnvironment.self) private var env

    private var tab: Binding<MainTab> {
        Binding(get: { env.router.tab }, set: { env.router.tab = $0 })
    }

    private var sheet: Binding<AppSheet?> {
        Binding(get: { env.router.sheet }, set: { env.router.sheet = $0 })
    }

    var body: some View {
        TabView(selection: tab) {
            LiveMapView()
                .tabItem { Label(MainTab.live.title, systemImage: MainTab.live.symbol) }
                .tag(MainTab.live)

            MissionTabRoot()
                .tabItem { Label(MainTab.misi.title, systemImage: MainTab.misi.symbol) }
                .tag(MainTab.misi)

            SamplesView()
                .tabItem { Label(MainTab.sampel.title, systemImage: MainTab.sampel.symbol) }
                .tag(MainTab.sampel)

            InsightsView()
                .tabItem { Label(MainTab.data.title, systemImage: MainTab.data.symbol) }
                .tag(MainTab.data)

            AlertsView()
                .tabItem { Label(MainTab.amaran.title, systemImage: MainTab.amaran.symbol) }
                .badge(env.unreadAlertCount)
                .tag(MainTab.amaran)
        }
        .overlay(alignment: .top) { CriticalBanner() }
        .overlay(alignment: .bottom) { ShowcaseOverlay() }
        .sheet(item: sheet) { route in
            switch route {
            case .power:
                PowerView()
            case .settings:
                SettingsView()
            case .camera:
                CameraSheet()
            case .stationDetail(let id):
                StationDetailView(stationID: id)
            }
        }
    }
}

/// Header icons shared by every screen: Tenaga and Tetapan (plus the Demo badge).
struct RoverToolbar: ToolbarContent {
    @Environment(AppEnvironment.self) private var env

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if env.isDemo { DemoBadge() }
            Button {
                env.router.sheet = .power
            } label: {
                Image(systemName: "bolt.fill")
            }
            .accessibilityLabel("Tenaga")

            Button {
                env.router.sheet = .settings
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Tetapan")
        }
    }
}
