import SwiftUI

@main
struct BoltPickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu bar only: everything lives in the status item's popover.
        Settings { EmptyView() }
    }
}
