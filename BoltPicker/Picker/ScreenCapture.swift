import CoreMedia
import CoreVideo
import Foundation
import ScreenCaptureKit

/// Live capture of one display. It only runs while a pick is in progress.
/// Only the most recent frame is kept, in memory. Nothing is ever written to disk.
final class DisplayStream: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    let displayID: CGDirectDisplayID

    private let stream: SCStream
    private let queue = DispatchQueue(label: "com.boltsandstars.BoltPicker.frames", qos: .userInteractive)
    private let lock = NSLock()
    private var latest: CVPixelBuffer? // guarded by `lock`

    private init(displayID: CGDirectDisplayID, stream: SCStream) {
        self.displayID = displayID
        self.stream = stream
        super.init()
    }

    /// Starts one stream per connected display. Every window of this app
    /// (the loupe and the overlays) is left out, so the loupe never captures itself.
    static func startAll() async throws -> [DisplayStream] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        let pid = ProcessInfo.processInfo.processIdentifier
        let ownApps = content.applications.filter { $0.processID == pid }
        let ownWindows = content.windows.filter { $0.owningApplication?.processID == pid }

        var started: [DisplayStream] = []
        do {
            for display in content.displays {
                let filter = ownApps.isEmpty
                    ? SCContentFilter(display: display, excludingWindows: ownWindows)
                    : SCContentFilter(display: display, excludingApplications: ownApps, exceptingWindows: [])

                let config = SCStreamConfiguration()
                let size = pixelSize(of: display)
                config.width = size.width
                config.height = size.height
                config.pixelFormat = kCVPixelFormatType_32BGRA
                config.colorSpaceName = CGColorSpace.sRGB
                config.showsCursor = false
                config.capturesAudio = false
                config.queueDepth = 3
                config.minimumFrameInterval = CMTime(value: 1, timescale: 60)

                let stream = SCStream(filter: filter, configuration: config, delegate: nil)
                let output = DisplayStream(displayID: display.displayID, stream: stream)
                try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: output.queue)
                try await stream.startCapture()
                started.append(output)
            }
        } catch {
            for s in started { await s.stop() }
            throw error
        }
        return started
    }

    /// The backing pixel size of the display's current mode, e.g. 3024×1964 on a
    /// MacBook Pro running at 1512×982 points.
    private static func pixelSize(of display: SCDisplay) -> (width: Int, height: Int) {
        if let mode = CGDisplayCopyDisplayMode(display.displayID), mode.pixelWidth > 0, mode.pixelHeight > 0 {
            return (mode.pixelWidth, mode.pixelHeight)
        }
        return (display.width * 2, display.height * 2)
    }

    func stop() async {
        try? await stream.stopCapture()
        lock.withLock { latest = nil }
    }

    /// Runs `body` on the newest frame. Returns `nil` if no frame has arrived yet.
    func withLatestFrame<T>(_ body: (FrameView) -> T) -> T? {
        guard let buffer = lock.withLock({ latest }) else { return nil }
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let view = FrameView(
            base: UnsafeRawPointer(base),
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            width: CVPixelBufferGetWidth(buffer),
            height: CVPixelBufferGetHeight(buffer)
        )
        return body(view)
    }

    // MARK: SCStreamOutput

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid else { return }
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
            as? [[SCStreamFrameInfo: Any]],
           let rawStatus = attachments.first?[.status] as? Int,
           let status = SCFrameStatus(rawValue: rawStatus),
           status != .complete {
            return // idle/blank frames carry no new pixels
        }
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        lock.withLock { latest = pixelBuffer }
    }
}
