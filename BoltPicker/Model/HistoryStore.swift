import Foundation
import Observation

/// The most recent picked colors, newest first, saved in UserDefaults
/// (inside the app's sandbox container).
@MainActor
@Observable
final class HistoryStore {
    static let limit = 30
    static let defaultsKey = "colorHistory"

    private(set) var colors: [HexColor]

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.stringArray(forKey: Self.defaultsKey) ?? []
        var seen = Set<HexColor>()
        colors = saved
            .compactMap(HexColor.init(hex:))
            .filter { seen.insert($0).inserted }
            .prefix(Self.limit)
            .map { $0 }
    }

    /// Adds a color to the front. If it's already in the list, it moves to the front.
    func add(_ color: HexColor) {
        colors.removeAll { $0 == color }
        colors.insert(color, at: 0)
        if colors.count > Self.limit {
            colors.removeLast(colors.count - Self.limit)
        }
        save()
    }

    func remove(_ color: HexColor) {
        colors.removeAll { $0 == color }
        save()
    }

    func clear() {
        colors.removeAll()
        save()
    }

    private func save() {
        defaults.set(colors.map(\.canonical), forKey: Self.defaultsKey)
    }
}
