import SwiftUI

struct AboutView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LogoLockup(compact: true)
                Text("“Dari Tasik ke Data. Dari Data ke Tindakan.”")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    KeyValueRow("Versi", "1.0 (demo)")
                    Divider()
                    KeyValueRow("Pasukan", "MCKK Robotics")
                    Divider()
                    KeyValueRow("Rover", env.roverName)
                    Divider()
                    KeyValueRow("Model AR", RoverNotificationBridge.hasRealityFile ? "Rover.reality" : "Model sementara")
                }
                .cardStyle()

                Text("LakeRover ialah rover pensampelan air tasik autonomi. Aplikasi ini memantau misi, merekod sampel dan menukar data menjadi tindakan.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.gutter)
        }
        .background(Theme.screenBackground)
        .navigationTitle("Tentang")
        .navigationBarTitleDisplayMode(.inline)
    }
}
