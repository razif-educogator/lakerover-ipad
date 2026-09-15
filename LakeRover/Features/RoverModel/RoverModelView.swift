import SwiftUI

struct RoverModelView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var model = RoverModelViewModel()

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(RoverGroup.allCases, id: \.self) { group in
                    Chip(title: group.label, selected: model.group == group) {
                        model.select(group)
                    }
                }
                Spacer(minLength: 8)
                Chip(title: Localization.t("Skala sebenar"), selected: model.realScale) {
                    model.toggleScale()
                }
            }

            stage
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))

            if model.isPlayingSampling || model.samplingStep != nil {
                StepBar(current: model.samplingStep)
                    .padding(.horizontal, 4)
            }

            ComponentInfoCard(component: model.selected)

            HStack(spacing: 12) {
                PrimaryButton("Main demo pensampelan", systemImage: "play.fill", enabled: !model.isPlayingSampling) {
                    model.playSampling()
                }
            }

            Text(footnote)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.gutter)
        .background(Theme.screenBackground)
        .navigationTitle("Model AR")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { RoverToolbar() }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    @ViewBuilder private var stage: some View {
        #if canImport(ARKit) && canImport(RealityKit)
        if FeatureFlags.arEnabled {
            RoverARView(model: model)
        } else {
            RoverDiagramView(model: model)
        }
        #else
        RoverDiagramView(model: model)
        #endif
    }

    private var footnote: String {
        model.usingPlaceholder
            ? Localization.t("Model sementara — gantikan Resources/Rover.reality dengan eksport Reality Composer.")
            : Localization.t("Ketik komponen untuk penerangan.")
    }
}
