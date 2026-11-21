import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let history = HistoryStore()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var session: PickerSession?

    func applicationDidFinishLaunching(_ notification: Notification) {
        SettingsKey.registerDefaults()
        // Unit tests run inside the app. Don't add a menu bar icon for them.
        guard NSClassFromString("XCTestCase") == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: "Bolt Picker")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        statusItem = item

        let content = PopoverView(
            history: history,
            onPick: { [weak self] in self?.startPick() },
            onCopy: { [weak self] text in self?.copy(text) },
            onQuit: { NSApp.terminate(nil) }
        )
        let host = NSHostingController(rootView: content)
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
        popover.behavior = .transient
        popover.animates = true
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate()
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func startPick() {
        guard session == nil else { return }
        popover.performClose(nil)

        let session = PickerSession()
        self.session = session
        Task { @MainActor in
            let color = await session.run()
            self.session = nil
            guard let color else { return }
            let text = HexFormat.current.string(color)
            Clipboard.copy(text)
            history.add(color)
            CopiedHUD.show(color: color, text: text, at: NSEvent.mouseLocation)
        }
    }

    private func copy(_ text: String) {
        Clipboard.copy(text)
    }
}
