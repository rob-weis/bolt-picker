import AppKit
import SwiftUI

/// A short "Copied #eb5244" toast shown next to the cursor after a pick.
@MainActor
enum CopiedHUD {
    private static var panel: NSPanel?
    private static var hideTask: Task<Void, Never>?

    static func show(color: HexColor, text: String, at point: CGPoint) {
        hideTask?.cancel()
        panel?.orderOut(nil)

        let host = NSHostingView(rootView: HUDContent(color: color, text: text))
        host.layoutSubtreeIfNeeded()
        let size = host.fittingSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.level = .screenSaver
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.contentView = host
        panel.setFrameOrigin(NSPoint(x: point.x + 14, y: point.y - size.height - 14))
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        Self.panel = panel

        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(850))
            guard !Task.isCancelled else { return }
            await NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                panel.animator().alphaValue = 0
            }
            guard !Task.isCancelled else { return }
            panel.orderOut(nil)
            if Self.panel === panel { Self.panel = nil }
        }
    }
}

private struct HUDContent: View {
    let color: HexColor
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color.swiftUIColor)
                .overlay(Circle().strokeBorder(.primary.opacity(0.2), lineWidth: 0.5))
                .frame(width: 14, height: 14)
            Text("Copied")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
        }
        .font(.system(size: 13))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.primary.opacity(0.1), lineWidth: 0.5))
        .fixedSize()
    }
}

extension HexColor {
    var swiftUIColor: Color {
        Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
