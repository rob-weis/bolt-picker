import AppKit
import CoreGraphics

/// One pick, from start to finish: check permission, start capture, show the
/// loupe, wait for a click or Esc, then shut everything down.
@MainActor
final class PickerSession {
    private var streams: [CGDirectDisplayID: DisplayStream] = [:]
    private var overlays: [OverlayWindow] = []
    private var loupe: LoupeWindow?
    private var timer: Timer?
    private var resignObserver: NSObjectProtocol?
    private var continuation: CheckedContinuation<HexColor?, Never>?
    private var cursorHidden = false
    private var finished = false
    private let format = HexFormat.current

    /// Returns the picked color, or `nil` if the pick was cancelled or couldn't start.
    func run() async -> HexColor? {
        guard ensurePermission() else { return nil }

        do {
            let started = try await DisplayStream.startAll()
            streams = Dictionary(uniqueKeysWithValues: started.map { ($0.displayID, $0) })
        } catch {
            await stopStreams()
            showCaptureError(error)
            return nil
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            presentUI()
        }
    }

    // MARK: - Permission

    private func ensurePermission() -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }

        let defaults = UserDefaults.standard
        let askedBefore = defaults.bool(forKey: SettingsKey.didRequestScreenCapture)
        defaults.set(true, forKey: SettingsKey.didRequestScreenCapture)

        // The first time, macOS shows its own prompt.
        if CGRequestScreenCaptureAccess() { return true }
        if askedBefore { showPermissionAlert() }
        return false
    }

    private func showPermissionAlert() {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "Bolt Picker needs Screen Recording access"
        alert.informativeText = """
            To read the color under the cursor, turn on Bolt Picker in \
            System Settings ▸ Privacy & Security ▸ Screen & System Audio Recording, \
            then quit and reopen Bolt Picker.

            The screen is only read while you are picking, and nothing is saved or sent anywhere.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    private func showCaptureError(_ error: Error) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "Couldn't start the color picker"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }

    // MARK: - UI

    private func presentUI() {
        NSApp.activate()

        for screen in NSScreen.screens {
            let overlay = OverlayWindow(screen: screen)
            overlay.onPick = { [weak self] in self?.pick() }
            overlay.onCancel = { [weak self] in self?.finish(with: nil) }
            overlay.orderFrontRegardless()
            overlays.append(overlay)
        }
        let screenUnderMouse = ScreenGeometry.indexOfScreen(
            containing: NSEvent.mouseLocation, in: overlays.map(\.frame)
        ) ?? 0
        if overlays.indices.contains(screenUnderMouse) {
            overlays[screenUnderMouse].makeKeyAndOrderFront(nil)
        }

        let loupe = LoupeWindow()
        self.loupe = loupe
        refresh()
        loupe.orderFrontRegardless()

        NSCursor.hide()
        cursorHidden = true

        // Redraw at screen rate. It's cheap: a 15×15 read from memory.
        let timer = Timer(timeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { _ = self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        // Switching apps (e.g. ⌘-Tab) cancels the pick.
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.finish(with: nil) }
        }
    }

    /// Samples the pixels around the cursor and updates the loupe.
    @discardableResult
    private func refresh() -> HexColor? {
        guard !finished, let loupe else { return nil }
        let mouse = NSEvent.mouseLocation
        loupe.center(on: mouse)

        let screens = NSScreen.screens
        guard let index = ScreenGeometry.indexOfScreen(containing: mouse, in: screens.map(\.frame)),
              let displayID = screens[index].displayID,
              let stream = streams[displayID] else {
            loupe.loupeView.update(cells: [], center: nil, label: "")
            return nil
        }
        let frame = screens[index].frame
        let radius = LoupeView.gridCount / 2

        let sample = stream.withLatestFrame { view -> (cells: [HexColor?], center: HexColor?) in
            let p = ScreenGeometry.pixel(
                for: mouse, screenFrame: frame, pixelWidth: view.width, pixelHeight: view.height
            )
            return (view.grid(centerX: p.x, centerY: p.y, radius: radius), view.color(x: p.x, y: p.y))
        }
        let center = sample?.center
        loupe.loupeView.update(
            cells: sample?.cells ?? [],
            center: center,
            label: center.map(format.string) ?? "…"
        )
        return center
    }

    private func pick() {
        // Sample once more at the exact click position. Ignore clicks before the first frame arrives.
        guard let color = refresh() else { return }
        finish(with: color)
    }

    private func finish(with color: HexColor?) {
        guard !finished else { return }
        finished = true

        timer?.invalidate()
        timer = nil
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        resignObserver = nil
        if cursorHidden {
            NSCursor.unhide()
            cursorHidden = false
        }
        loupe?.orderOut(nil)
        loupe = nil
        overlays.forEach { $0.orderOut(nil) }
        overlays.removeAll()

        Task { await stopStreams() }

        continuation?.resume(returning: color)
        continuation = nil
    }

    private func stopStreams() async {
        let all = Array(streams.values)
        streams.removeAll()
        for stream in all { await stream.stop() }
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
