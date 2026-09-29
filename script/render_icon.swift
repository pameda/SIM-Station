import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for (name, pixels) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
    let size = CGFloat(pixels)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let rect = NSRect(x: size * 0.09, y: size * 0.09, width: size * 0.82, height: size * 0.82)
    let shape = NSBezierPath(roundedRect: rect, xRadius: size * 0.19, yRadius: size * 0.19)
    NSGradient(starting: NSColor(calibratedRed: 0.07, green: 0.32, blue: 0.85, alpha: 1),
               ending: NSColor(calibratedRed: 0.13, green: 0.67, blue: 0.96, alpha: 1))!.draw(in: shape, angle: 65)
    let symbol = NSImage(systemSymbolName: "phone.connection.fill", accessibilityDescription: nil)!
        .withSymbolConfiguration(.init(pointSize: size * 0.5, weight: .medium))!
        .withSymbolConfiguration(.init(paletteColors: [.white]))!
    let iconRect = NSRect(x: size * 0.24, y: size * 0.25, width: size * 0.52, height: size * 0.5)
    symbol.draw(in: iconRect)
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name + ".png"))
}
