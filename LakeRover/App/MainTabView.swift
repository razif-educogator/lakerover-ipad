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
                .tabItem { tabLabel(.live) }
                .tag(MainTab.live)

            MissionTabRoot()
                .tabItem { tabLabel(.misi) }
                .tag(MainTab.misi)

            SamplesView()
                .tabItem { tabLabel(.sampel) }
                .tag(MainTab.sampel)

            InsightsView()
                .tabItem { tabLabel(.data) }
                .tag(MainTab.data)

            AlertsView()
                .tabItem { tabLabel(.amaran) }
                .badge(env.unreadAlertCount)
                .tag(MainTab.amaran)
        }
        .overlay(alignment: .top) { CriticalBanner() }
        // A safe-area inset rather than an overlay, so the caption never covers a control.
        .safeAreaInset(edge: .bottom, spacing: 0) { ShowcaseOverlay() }
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

/// Tab labels must never wrap — "Live" was breaking to "Liv/e" in the iPad top tab bar.
/// `fixedSize` keeps each label at its natural width instead of letting the bar compress it.
private extension MainTabView {
    func tabLabel(_ tab: MainTab) -> some View {
        Label {
            Text(tab.title)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        } icon: {
            Image(systemName: tab.symbol)
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
