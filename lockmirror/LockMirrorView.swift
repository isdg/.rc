import ScreenSaver

// Draws the snapshot Hammerspoon left for this view's display just before
// starting the saver, so a locked screen looks exactly as it was left.
@objc(LockMirrorView)
final class LockMirrorView: ScreenSaverView {
    private var image: NSImage?

    // Sandboxed, so this is legacyScreenSaver's container, where
    // hammerspoon/lockmirror.lua writes lockmirror-<display UUID>.png.
    private var shot: URL? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard
            let id = window?.screen?.deviceDescription[key]
                as? CGDirectDisplayID,
            let uuid = CGDisplayCreateUUIDFromDisplayID(id)?
                .takeRetainedValue(),
            let name = CFUUIDCreateString(nil, uuid) as String?
        else { return nil }
        return URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("lockmirror-\(name).png")
    }

    override func startAnimation() {
        super.startAnimation()
        image = shot.flatMap(NSImage.init(contentsOf:))
        needsDisplay = true
    }

    // The host process outlives the saver, and a full-resolution snapshot
    // is hundreds of megabytes.
    override func stopAnimation() {
        super.stopAnimation()
        image = nil
    }

    override func draw(_ rect: NSRect) {
        guard let image else {
            NSColor.black.setFill()
            bounds.fill()
            return
        }
        image.draw(in: bounds)
    }
}
