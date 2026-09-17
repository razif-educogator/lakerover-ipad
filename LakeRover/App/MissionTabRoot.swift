import SwiftUI

/// The Misi tab: Mission Picker when no mission is active, Mission Progress otherwise.
/// Owns the push stack for Sampling, the Mission Editor and the Rover Model.
struct MissionTabRoot: View {
    @Environment(AppEnvironment.self) private var env

    private var path: Binding<[MissionRoute]> {
        Binding(get: { env.router.missionPath }, set: { env.router.missionPath = $0 })
    }

    var body: some View {
        NavigationStack(path: path) {
            Group {
                if env.hasActiveMission {
                    MissionProgressView()
                } else {
                    MissionPickerView()
                }
            }
            .navigationDestination(for: MissionRoute.self) { route in
                switch route {
                case .progress: MissionProgressView()
                case .sampling: SamplingView()
                case .editor: MissionEditorView()
                case .roverModel: RoverModelView()
                case .picker: MissionPickerView()
                }
            }
        }
    }
}
