import Foundation
import Testing
@testable import BoltPicker

@MainActor
struct HistoryStoreTests {
    private func freshDefaults() -> UserDefaults {
        let name = "BoltPickerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func color(_ i: Int) -> HexColor {
        HexColor(r: UInt8(i), g: UInt8(255 - i), b: 7)
    }

    @Test func newestFirst() {
        let store = HistoryStore(defaults: freshDefaults())
        store.add(color(1))
        store.add(color(2))
        #expect(store.colors == [color(2), color(1)])
    }

    @Test func repeatedColorMovesToFrontWithoutDuplicating() {
        let store = HistoryStore(defaults: freshDefaults())
        store.add(color(1))
        store.add(color(2))
        store.add(color(3))
        store.add(color(1))
        #expect(store.colors == [color(1), color(3), color(2)])
    }

    @Test func capsAtThirty() {
        let store = HistoryStore(defaults: freshDefaults())
        for i in 0..<45 { store.add(color(i)) }
        #expect(store.colors.count == 30)
        #expect(store.colors.first == color(44))
        #expect(store.colors.last == color(15))
    }

    @Test func persistsAcrossInstances() {
        let defaults = freshDefaults()
        let first = HistoryStore(defaults: defaults)
        first.add(color(1))
        first.add(color(2))
        let second = HistoryStore(defaults: defaults)
        #expect(second.colors == [color(2), color(1)])
    }

    @Test func removeAndClear() {
        let defaults = freshDefaults()
        let store = HistoryStore(defaults: defaults)
        store.add(color(1))
        store.add(color(2))
        store.remove(color(1))
        #expect(store.colors == [color(2)])
        store.clear()
        #expect(store.colors.isEmpty)
        #expect(HistoryStore(defaults: defaults).colors.isEmpty)
    }

    @Test func ignoresCorruptSavedData() {
        let defaults = freshDefaults()
        defaults.set(["EB5244", "nope", "eb5244", "123456"], forKey: HistoryStore.defaultsKey)
        let store = HistoryStore(defaults: defaults)
        #expect(store.colors.map(\.canonical) == ["EB5244", "123456"])
    }
}
