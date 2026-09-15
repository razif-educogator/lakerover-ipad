import Foundation

/// `Text("…")` follows `\.locale` from the SwiftUI environment, but plain `String` lookups do
/// not — they use the *device* locale. This holder keeps the two in step so switching the
/// language in Tetapan changes every string, not just the ones inside `Text` (R12.2).
@MainActor
enum Localization {
    static var language: AppLanguage = .ms

    static var locale: Locale { language.locale }

    static func t(_ key: String.LocalizationValue) -> String {
        var resource = LocalizedStringResource(key)
        resource.locale = locale
        return String(localized: resource)
    }
}
