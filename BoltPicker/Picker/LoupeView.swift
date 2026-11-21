import AppKit

/// The floating magnifier: a circle of enlarged pixels with the center pixel
/// outlined, and a label underneath showing that pixel's hex.
@MainActor
final class LoupeWindow: NSPanel {
    let loupeView = LoupeView(frame: NSRect(origin: .zero, size: LoupeView.size))

    init() {
        super.init(
            contentRect: NSRect(origin: .zero, size: LoupeView.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        sharingType = .none
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        contentView = loupeView
    }

    /// Places the window so the center pixel sits exactly under the cursor.
    func center(on point: CGPoint) {
        let c = LoupeView.circleCenter
        setFrameOrigin(NSPoint(x: point.x - c.x, y: point.y - (LoupeView.size.height - c.y)))
    }
}

@MainActor
final class LoupeView: NSView {
    static let gridCount = 15 // odd, so there is a single center pixel
    static let cellSize: CGFloat = 10
    static let margin: CGFloat = 14
    static let pillSize = CGSize(width: 112, height: 28)
    static var diameter: CGFloat { CGFloat(gridCount) * cellSize }
    static var circleRect: CGRect { CGRect(x: margin, y: margin, width: diameter, height: diameter) }
    static var circleCenter: CGPoint { CGPoint(x: circleRect.midX, y: circleRect.midY) }
    static var pillRect: CGRect {
        CGRect(
            x: circleRect.midX - pillSize.width / 2,
            y: circleRect.maxY - 22,
            width: pillSize.width,
            height: pillSize.height
        )
    }
    static var size: CGSize { CGSize(width: diameter + margin * 2, height: pillRect.maxY + margin) }

    private(set) var cells: [HexColor?] = []
    private(set) var center: HexColor?
    private(set) var label = ""

    override var isFlipped: Bool { true }

    func update(cells: [HexColor?], center: HexColor?, label: String) {
        guard cells != self.cells || label != self.label else { return }
        self.cells = cells
        self.center = center
        self.label = label
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let circle = Self.circleRect
        let n = Self.gridCount
        let cell = Self.cellSize

        // Drop shadow under the ring.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: 3), blur: 10, color: CGColor(gray: 0, alpha: 0.4))
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fillEllipse(in: circle.insetBy(dx: -3, dy: -3))
        ctx.restoreGState()

        // Magnified pixels, in sRGB so they look the same as on screen.
        ctx.saveGState()
        ctx.addEllipse(in: circle)
        ctx.clip()
        ctx.setFillColor(CGColor(gray: 0.5, alpha: 1))
        ctx.fill(circle)
        if cells.count == n * n {
            for row in 0..<n {
                for col in 0..<n {
                    guard let c = cells[row * n + col] else { continue }
                    ctx.setFillColor(c.cgColor)
                    ctx.fill(CGRect(x: circle.minX + CGFloat(col) * cell,
                                    y: circle.minY + CGFloat(row) * cell,
                                    width: cell, height: cell))
                }
            }
        }
        // Faint pixel grid.
        ctx.setStrokeColor(CGColor(gray: 0, alpha: 0.12))
        ctx.setLineWidth(0.5)
        for i in 1..<n {
            let o = CGFloat(i) * cell
            ctx.move(to: CGPoint(x: circle.minX + o, y: circle.minY))
            ctx.addLine(to: CGPoint(x: circle.minX + o, y: circle.maxY))
            ctx.move(to: CGPoint(x: circle.minX, y: circle.minY + o))
            ctx.addLine(to: CGPoint(x: circle.maxX, y: circle.minY + o))
        }
        ctx.strokePath()
        ctx.restoreGState()

        // Ring.
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 1))
        ctx.setLineWidth(3)
        ctx.strokeEllipse(in: circle.insetBy(dx: -1.5, dy: -1.5))
        ctx.setStrokeColor(CGColor(gray: 0, alpha: 0.25))
        ctx.setLineWidth(0.5)
        ctx.strokeEllipse(in: circle.insetBy(dx: -3.25, dy: -3.25))

        // Center pixel outline: dark outside, white inside, so it shows on any color.
        let mid = CGFloat(n / 2) * cell
        let target = CGRect(x: circle.minX + mid, y: circle.minY + mid, width: cell, height: cell)
        ctx.setStrokeColor(CGColor(gray: 0, alpha: 0.75))
        ctx.setLineWidth(1)
        ctx.stroke(target.insetBy(dx: -1.5, dy: -1.5))
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 1))
        ctx.setLineWidth(1)
        ctx.stroke(target.insetBy(dx: -0.5, dy: -0.5))

        drawPill(ctx)
    }

    private func drawPill(_ ctx: CGContext) {
        let pill = Self.pillRect
        let path = CGPath(roundedRect: pill, cornerWidth: pill.height / 2, cornerHeight: pill.height / 2, transform: nil)

        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: 2), blur: 6, color: CGColor(gray: 0, alpha: 0.3))
        ctx.addPath(path)
        ctx.setFillColor(CGColor(gray: 0.98, alpha: 1))
        ctx.fillPath()
        ctx.restoreGState()

        // Color dot.
        let dot = CGRect(x: pill.minX + 6, y: pill.minY + 5, width: pill.height - 10, height: pill.height - 10)
        ctx.setFillColor(center?.cgColor ?? CGColor(gray: 0.5, alpha: 1))
        ctx.fillEllipse(in: dot)
        ctx.setStrokeColor(CGColor(gray: 0, alpha: 0.2))
        ctx.setLineWidth(0.5)
        ctx.strokeEllipse(in: dot)

        // Hex text.
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor(white: 0.3, alpha: 1),
        ]
        let text = NSAttributedString(string: label, attributes: attrs)
        let textSize = text.size()
        let textArea = CGRect(x: dot.maxX + 6, y: pill.minY, width: pill.maxX - dot.maxX - 12, height: pill.height)
        text.draw(at: CGPoint(x: textArea.midX - textSize.width / 2, y: textArea.midY - textSize.height / 2))
    }
}

extension HexColor {
    var cgColor: CGColor {
        CGColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}
