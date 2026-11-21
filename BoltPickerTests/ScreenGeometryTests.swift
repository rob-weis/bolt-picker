import CoreGraphics
import Testing
@testable import BoltPicker

struct ScreenGeometryTests {
    // Primary display at 1x, and a Retina display placed to its right and 200 pt higher.
    let primary = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let retina = CGRect(x: 1920, y: 200, width: 1512, height: 982)

    @Test func findsScreenUnderPoint() {
        let frames = [primary, retina]
        #expect(ScreenGeometry.indexOfScreen(containing: CGPoint(x: 10, y: 10), in: frames) == 0)
        #expect(ScreenGeometry.indexOfScreen(containing: CGPoint(x: 2000, y: 1100), in: frames) == 1)
        #expect(ScreenGeometry.indexOfScreen(containing: CGPoint(x: 2000, y: 100), in: frames) == nil)
        // The top edge (y == maxY) is where the very top row of pixels is.
        #expect(ScreenGeometry.indexOfScreen(containing: CGPoint(x: 5, y: 1080), in: frames) == 0)
    }

    @Test func mapsAt1x() {
        let p = ScreenGeometry.pixel(for: CGPoint(x: 100, y: 1080), screenFrame: primary,
                                     pixelWidth: 1920, pixelHeight: 1080)
        #expect(p.x == 100 && p.y == 0) // y flips: top of screen is row 0
        let q = ScreenGeometry.pixel(for: CGPoint(x: 100, y: 1), screenFrame: primary,
                                     pixelWidth: 1920, pixelHeight: 1080)
        #expect(q.y == 1079)
    }

    @Test func mapsAt2xIncludingHalfPoints() {
        let w = 3024, h = 1964
        let topLeft = ScreenGeometry.pixel(for: CGPoint(x: 1920, y: 1182), screenFrame: retina,
                                           pixelWidth: w, pixelHeight: h)
        #expect(topLeft.x == 0 && topLeft.y == 0)

        let half = ScreenGeometry.pixel(for: CGPoint(x: 1920.5, y: 1181.5), screenFrame: retina,
                                        pixelWidth: w, pixelHeight: h)
        #expect(half.x == 1 && half.y == 1)

        let mid = ScreenGeometry.pixel(for: CGPoint(x: 1920 + 756, y: 200 + 491), screenFrame: retina,
                                       pixelWidth: w, pixelHeight: h)
        #expect(mid.x == 1512 && mid.y == 982)
    }

    @Test func clampsToBuffer() {
        let p = ScreenGeometry.pixel(for: CGPoint(x: 5000, y: -50), screenFrame: primary,
                                     pixelWidth: 1920, pixelHeight: 1080)
        #expect(p.x == 1919 && p.y == 1079)
        let q = ScreenGeometry.pixel(for: CGPoint(x: -3, y: 9999), screenFrame: primary,
                                     pixelWidth: 1920, pixelHeight: 1080)
        #expect(q.x == 0 && q.y == 0)
    }
}
