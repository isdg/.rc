#!/usr/bin/env bash
# Compiles Tone.swift with a small driver and checks how it reads its plist
# and what it does to black, mid grey and white.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [ "$(uname)" != Darwin ]; then
    echo "skip: LockMirror is Darwin-only"
    exit 0
fi

cat > "$tmp/main.swift" << 'EOF'
import CoreGraphics
import Foundation

var fails = 0

func check(_ what: String, _ ok: Bool) {
    print(ok ? "ok   \(what)" : "FAIL \(what)")
    if !ok { fails += 1 }
}

// One sRGB grey pixel through the tone, read back as a byte.
func grey(_ v: UInt8, _ tone: Tone) -> Int {
    let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
    let info = CGImageAlphaInfo.noneSkipLast.rawValue
    var px: [UInt8] = [v, v, v, 255]
    let src = CGContext(
        data: &px, width: 1, height: 1, bitsPerComponent: 8,
        bytesPerRow: 4, space: srgb, bitmapInfo: info)!.makeImage()!
    var out: [UInt8] = [0, 0, 0, 0]
    let dst = CGContext(
        data: &out, width: 1, height: 1, bitsPerComponent: 8,
        bytesPerRow: 4, space: srgb, bitmapInfo: info)!
    dst.draw(tone.apply(to: src)!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    return Int(out[0])
}

let dir = URL(fileURLWithPath: CommandLine.arguments[1])
let plist = dir.appendingPathComponent("tone.plist")

check("the default is the identity", Tone().isIdentity)
check("a missing plist is the identity",
    Tone(contentsOf: dir.appendingPathComponent("none.plist")).isIdentity)
NSDictionary(dictionary: ["exposure": 0.25]).write(to: plist, atomically: true)
check("a missing key keeps its default",
    Tone(contentsOf: plist) == Tone(exposure: 0.25, gamma: 1))
NSDictionary(dictionary: ["exposure": 1, "gamma": 0.5])
    .write(to: plist, atomically: true)
check("integers are read as numbers",
    Tone(contentsOf: plist) == Tone(exposure: 1, gamma: 0.5))

check("identity keeps mid grey", abs(grey(128, Tone()) - 128) <= 1)
check("exposure lifts mid grey", grey(128, Tone(exposure: 0.5)) > 140)
check("exposure clips white", grey(255, Tone(exposure: 0.5)) == 255)
check("gamma below 1 lifts mid grey", grey(128, Tone(gamma: 0.8)) > 135)
check("gamma keeps black", grey(0, Tone(gamma: 0.8)) == 0)
check("gamma keeps white", grey(255, Tone(gamma: 0.8)) >= 254)

print(fails == 0 ? "all passed" : "\(fails) failed")
exit(fails == 0 ? 0 : 1)
EOF

swiftc -O -o "$tmp/tone" "$here/Tone.swift" "$tmp/main.swift"
"$tmp/tone" "$tmp"
