import CoreGraphics

/// Pure coordinate math, kept separate so it can be unit-tested.
enum ScreenGeometry {
    /// Index of the screen frame containing `point`, in AppKit global coordinates
    /// (origin at the bottom-left of the primary display, y going up).
    /// The edges count as inside, so the very top row of pixels is still found.
    static func indexOfScreen(containing point: CGPoint, in frames: [CGRect]) -> Int? {
        frames.firstIndex { f in
            point.x >= f.minX && point.x <= f.maxX && point.y >= f.minY && point.y <= f.maxY
        }
    }

    /// The pixel under `point` in a frame buffer that covers `screenFrame`.
    /// Pixel (0, 0) is the top-left. Out-of-range values are clamped to the buffer.
    static func pixel(
        for point: CGPoint,
        screenFrame: CGRect,
        pixelWidth: Int,
        pixelHeight: Int
    ) -> (x: Int, y: Int) {
        guard screenFrame.width > 0, screenFrame.height > 0,
              pixelWidth > 0, pixelHeight > 0 else { return (0, 0) }
        let scaleX = CGFloat(pixelWidth) / screenFrame.width
        let scaleY = CGFloat(pixelHeight) / screenFrame.height
        let localX = (point.x - screenFrame.minX) * scaleX
        let localY = (screenFrame.maxY - point.y) * scaleY
        let x = Int(localX.rounded(.down))
        let y = Int(localY.rounded(.down))
        return (min(max(x, 0), pixelWidth - 1), min(max(y, 0), pixelHeight - 1))
    }
}

/// A read-only view of a 32-bit BGRA frame buffer. Only valid while the buffer is locked.
struct FrameView {
    let base: UnsafeRawPointer
    let bytesPerRow: Int
    let width: Int
    let height: Int

    func color(x: Int, y: Int) -> HexColor? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        let offset = y * bytesPerRow + x * 4
        return HexColor(
            r: base.load(fromByteOffset: offset + 2, as: UInt8.self),
            g: base.load(fromByteOffset: offset + 1, as: UInt8.self),
            b: base.load(fromByteOffset: offset, as: UInt8.self)
        )
    }

    /// A square of `(2 * radius + 1)²` pixels centered on (x, y), row by row from the top.
    /// Pixels outside the buffer are `nil`.
    func grid(centerX: Int, centerY: Int, radius: Int) -> [HexColor?] {
        var cells: [HexColor?] = []
        cells.reserveCapacity((2 * radius + 1) * (2 * radius + 1))
        for dy in -radius...radius {
            for dx in -radius...radius {
                cells.append(color(x: centerX + dx, y: centerY + dy))
            }
        }
        return cells
    }
}
