import CoreImage
import Foundation

// macOS draws screen savers slightly dimmed, so the snapshot is brightened
// back: exposure scales linear light by 2^exposure, then gamma raises it to
// that power (below 1 lifts mid-tones while black and white stay put).
struct Tone: Equatable {
    var exposure = 0.0
    var gamma = 1.0

    var isIdentity: Bool { self == Tone() }

    // Written by hammerspoon/lockmirror.lua; a missing key keeps its default.
    init(exposure: Double = 0, gamma: Double = 1) {
        self.exposure = exposure
        self.gamma = gamma
    }

    init(contentsOf url: URL) {
        let plist = NSDictionary(contentsOf: url) ?? [:]
        self.init(
            exposure: (plist["exposure"] as? NSNumber)?.doubleValue ?? 0,
            gamma: (plist["gamma"] as? NSNumber)?.doubleValue ?? 1)
    }

    func apply(to image: CIImage) -> CIImage {
        image
            .applyingFilter(
                "CIExposureAdjust", parameters: [kCIInputEVKey: exposure])
            .applyingFilter("CIGammaAdjust", parameters: ["inputPower": gamma])
    }

    func apply(to image: CGImage) -> CGImage? {
        let input = CIImage(cgImage: image)
        return CIContext().createCGImage(
            apply(to: input), from: input.extent)
    }
}
