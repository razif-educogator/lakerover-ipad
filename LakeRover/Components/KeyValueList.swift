import SwiftUI

struct KeyValueRow: View {
    var key: LocalizedStringKey
    var value: String
    var tint: Color?

    init(_ key: LocalizedStringKey, _ value: String, tint: Color? = nil) {
        self.key = key
        self.value = value
        self.tint = tint
    }

    var body: some View {
        HStack {
            Text(key)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(tint ?? .primary)
                .monospacedDigit()
        }
        .font(.subheadline)
        .padding(.vertical, 7)
    }
}

struct KeyValueList<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
    }
}
