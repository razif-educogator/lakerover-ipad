import SwiftUI

/// Placeholder for the rover's live camera feed — the demo has no video link.
struct CameraSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.cardCorner)
                        .fill(Color(.systemGray5))
                    VStack(spacing: 8) {
                        Image(systemName: "video.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Suapan kamera tidak tersedia dalam mod demo")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .aspectRatio(4.0 / 3.0, contentMode: .fit)

                Text("Kamera 360° rover menstrim melalui pautan 4G semasa misi sebenar.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(Theme.gutter)
            .navigationTitle("Kamera langsung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
    }
}
