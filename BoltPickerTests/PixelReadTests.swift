import Foundation
import Testing
@testable import BoltPicker

struct PixelReadTests {
    /// A 3×2 BGRA buffer with padding at the end of each row, like real frame buffers.
    let width = 3
    let height = 2
    let bytesPerRow = 16
    let pixels: [[HexColor]] = [
        [HexColor(r: 0xEB, g: 0x52, b: 0x44), HexColor(r: 0, g: 0xFF, b: 0), HexColor(r: 0x12, g: 0x34, b: 0x56)],
        [HexColor(r: 255, g: 255, b: 255), HexColor(r: 0, g: 0, b: 0), HexColor(r: 1, g: 2, b: 3)],
    ]

    private func makeBuffer() -> [UInt8] {
        var bytes = [UInt8](repeating: 0xAA, count: bytesPerRow * height)
        for (y, row) in pixels.enumerated() {
            for (x, c) in row.enumerated() {
                let o = y * bytesPerRow + x * 4
                bytes[o] = c.b
                bytes[o + 1] = c.g
                bytes[o + 2] = c.r
                bytes[o + 3] = 0xFF
            }
        }
        return bytes
    }

    @Test func readsExactBGRAValues() {
        let bytes = makeBuffer()
        bytes.withUnsafeBytes { raw in
            let view = FrameView(base: raw.baseAddress!, bytesPerRow: bytesPerRow, width: width, height: height)
            for y in 0..<height {
                for x in 0..<width {
                    #expect(view.color(x: x, y: y) == pixels[y][x])
                }
            }
            #expect(view.color(x: 0, y: 0).map { HexFormat(includeHash: true, uppercase: false).string($0) } == "#eb5244")
        }
    }

    @Test func outOfBoundsIsNil() {
        let bytes = makeBuffer()
        bytes.withUnsafeBytes { raw in
            let view = FrameView(base: raw.baseAddress!, bytesPerRow: bytesPerRow, width: width, height: height)
            #expect(view.color(x: -1, y: 0) == nil)
            #expect(view.color(x: 3, y: 0) == nil) // would land in row padding
            #expect(view.color(x: 0, y: 2) == nil)
        }
    }

    @Test func gridIsRowMajorAndPadsOutside() {
        let bytes = makeBuffer()
        bytes.withUnsafeBytes { raw in
            let view = FrameView(base: raw.baseAddress!, bytesPerRow: bytesPerRow, width: width, height: height)
            let grid = view.grid(centerX: 0, centerY: 0, radius: 1)
            #expect(grid.count == 9)
            #expect(grid[0] == nil && grid[1] == nil && grid[2] == nil) // row above the buffer
            #expect(grid[3] == nil)                                      // left of the buffer
            #expect(grid[4] == pixels[0][0])                             // center
            #expect(grid[5] == pixels[0][1])
            #expect(grid[7] == pixels[1][0])
            #expect(grid[8] == pixels[1][1])
        }
    }
}
