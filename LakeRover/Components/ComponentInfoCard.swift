import SwiftUI

struct ComponentInfoCard: View {
    var component: RoverComponent?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let component {
                HStack(spacing: 8) {
                    Image(systemName: component.symbol)
                        .foregroundStyle(Theme.accent)
                    Text(component.title)
                        .font(.subheadline.weight(.semibold))
                    StatusPill(text: LocalizedStringKey(component.role), symbol: "tag", tint: Theme.accent)
                }
                Text(component.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Ketik komponen untuk penerangan")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.2), value: component)
        .cardStyle(padding: 12)
    }
}
