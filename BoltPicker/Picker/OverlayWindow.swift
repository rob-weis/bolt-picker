import AppKit

/// An invisible full-screen window that catches the click (pick) and Esc or
/// right-click (cancel) while picking. It is left out of screen capture.
@MainActor
final class OverlayWindow: NSWindow {
    var onPick: (() -> Void)?
    var onCancel: (() -> Void)?

    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        setFrame(screen.frame, display: false)
        isOpaque = false
        // Near-zero alpha (not fully clear) so the window server sends clicks
        // here instead of letting them fall through to the app underneath.
        backgroundColor = NSColor(white: 0, alpha: 0.004)
        hasShadow = false
        level = .screenSaver
        sharingType = .none
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let view = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.owner = self
        contentView = view
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
private final class OverlayView: NSView {
    weak var owner: OverlayWindow?

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) { owner?.onPick?() }
    override func rightMouseDown(with event: NSEvent) { owner?.onCancel?() }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc
            owner?.onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    // The overlays cover the menu bar too, so stop ⌘-shortcuts from leaking through.
    override func performKeyEquivalent(with event: NSEvent) -> Bool { true }
}
