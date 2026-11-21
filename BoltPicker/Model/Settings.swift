import Foundation

enum SettingsKey {
    static let includeHash = "includeHash"
    static let uppercase = "uppercaseHex"
    static let didRequestScreenCapture = "didRequestScreenCapture"

    /// Defaults: copy with `#`, lowercase letters (`#eb5244`).
    static func registerDefaults(_ defaults: UserDefaults = .standard) {
        defaults.register(defaults: [
            includeHash: true,
            uppercase: false,
        ])
    }
}
