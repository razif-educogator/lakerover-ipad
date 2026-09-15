import SwiftUI

enum ConnectionState: Equatable {
    case searching
    case connected(name: String, link: String, batteryPct: Int, satellites: Int)
    case notFound
}

struct ConnectionCard: View {
    var state: ConnectionState

    var body: some View {
        HStack(spacing: 12) {
            indicator
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if state == .searching {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    @ViewBuilder private var indicator: some View {
        switch state {
        case .searching:
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundStyle(.secondary)
        case .connected:
            Circle().fill(Theme.success).frame(width: 10, height: 10)
        case .notFound:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.warning)
        }
    }

    private var title: String {
        switch state {
        case .searching: Localization.t("Mencari rover…")
        case .connected(let name, _, _, _): "\(name) disambung"
        case .notFound: Localization.t("Rover tidak dijumpai")
        }
    }

    private var subtitle: String {
        switch state {
        case .searching:
            Localization.t("Menyemak pautan tempatan dan 4G")
        case .connected(_, let link, let battery, let satellites):
            "\(link) · Bateri \(battery)% · GPS \(satellites) satelit"
        case .notFound:
            Localization.t("Teruskan dengan mod demo — rover disimulasikan sepenuhnya.")
        }
    }
}
