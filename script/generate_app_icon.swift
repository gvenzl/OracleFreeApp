import AppKit
import Foundation

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = rootURL
    .appendingPathComponent("Sources")
    .appendingPathComponent("OracleFreeKit")
    .appendingPathComponent("Resources")

try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    let rect = NSRect(x: 0, y: 0, width: size, height: size)

    image.lockFocus()

    let cornerRadius = size * 0.215
    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    backgroundPath.addClip()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.42, green: 0.02, blue: 0.03, alpha: 1),
        NSColor(calibratedRed: 0.86, green: 0.05, blue: 0.06, alpha: 1),
        NSColor(calibratedRed: 0.98, green: 0.28, blue: 0.15, alpha: 1)
    ])
    gradient?.draw(in: backgroundPath, angle: -35)

    NSColor(calibratedWhite: 1, alpha: 0.12).setFill()
    NSBezierPath(ovalIn: NSRect(x: size * 0.55, y: size * 0.57, width: size * 0.62, height: size * 0.62)).fill()
    NSColor(calibratedWhite: 0, alpha: 0.18).setFill()
    NSBezierPath(ovalIn: NSRect(x: -size * 0.12, y: -size * 0.18, width: size * 0.68, height: size * 0.68)).fill()

    let containerRect = NSRect(x: size * 0.22, y: size * 0.20, width: size * 0.56, height: size * 0.58)
    let containerPath = NSBezierPath(roundedRect: containerRect, xRadius: size * 0.06, yRadius: size * 0.06)
    NSColor(calibratedWhite: 1, alpha: 0.18).setFill()
    containerPath.fill()
    NSColor(calibratedWhite: 1, alpha: 0.58).setStroke()
    containerPath.lineWidth = max(2, size * 0.018)
    containerPath.stroke()

    let cylinderWidth = size * 0.36
    let cylinderHeight = size * 0.42
    let cylinderX = (size - cylinderWidth) / 2
    let cylinderY = size * 0.30
    let ellipseHeight = size * 0.10
    let bodyRect = NSRect(x: cylinderX, y: cylinderY, width: cylinderWidth, height: cylinderHeight)

    NSColor(calibratedWhite: 1, alpha: 0.95).setFill()
    NSBezierPath(rect: NSRect(
        x: bodyRect.minX,
        y: bodyRect.minY + ellipseHeight / 2,
        width: bodyRect.width,
        height: bodyRect.height - ellipseHeight
    )).fill()

    let topEllipse = NSBezierPath(ovalIn: NSRect(
        x: bodyRect.minX,
        y: bodyRect.maxY - ellipseHeight,
        width: bodyRect.width,
        height: ellipseHeight
    ))
    let bottomEllipse = NSBezierPath(ovalIn: NSRect(
        x: bodyRect.minX,
        y: bodyRect.minY,
        width: bodyRect.width,
        height: ellipseHeight
    ))

    NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.36, alpha: 1).setFill()
    topEllipse.fill()
    NSColor(calibratedWhite: 1, alpha: 0.95).setFill()
    bottomEllipse.fill()

    NSColor(calibratedRed: 0.72, green: 0.03, blue: 0.04, alpha: 0.36).setStroke()
    for offset in [0.24, 0.43, 0.62] {
        let lineY = cylinderY + cylinderHeight * offset
        let line = NSBezierPath()
        line.move(to: NSPoint(x: cylinderX + size * 0.035, y: lineY))
        line.line(to: NSPoint(x: cylinderX + cylinderWidth - size * 0.035, y: lineY))
        line.lineWidth = max(1, size * 0.012)
        line.stroke()
    }

    NSColor(calibratedWhite: 1, alpha: 0.9).setFill()
    let badgeRect = NSRect(x: size * 0.57, y: size * 0.18, width: size * 0.18, height: size * 0.18)
    NSBezierPath(roundedRect: badgeRect, xRadius: size * 0.035, yRadius: size * 0.035).fill()
    NSColor(calibratedRed: 0.70, green: 0.02, blue: 0.03, alpha: 1).setFill()
    let dotSize = size * 0.035
    for x in [badgeRect.minX + size * 0.045, badgeRect.minX + size * 0.10] {
        for y in [badgeRect.minY + size * 0.045, badgeRect.minY + size * 0.10] {
            NSBezierPath(ovalIn: NSRect(x: x, y: y, width: dotSize, height: dotSize)).fill()
        }
    }

    image.unlockFocus()
    return image
}

func pngData(for image: NSImage) throws -> Data {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw CocoaError(.fileWriteUnknown)
    }

    return pngData
}

func writePNG(image: NSImage, to url: URL) throws {
    let pngData = try pngData(for: image)
    try pngData.write(to: url)
}

func writeICNS(entries: [(type: String, pngData: Data)], to url: URL) throws {
    var data = Data()

    func appendFourCC(_ value: String) {
        data.append(contentsOf: value.utf8)
    }

    func appendBigEndianUInt32(_ value: UInt32) {
        data.append(UInt8((value >> 24) & 0xff))
        data.append(UInt8((value >> 16) & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
        data.append(UInt8(value & 0xff))
    }

    let totalLength = entries.reduce(8) { partialResult, entry in
        partialResult + 8 + entry.pngData.count
    }

    appendFourCC("icns")
    appendBigEndianUInt32(UInt32(totalLength))

    for entry in entries {
        appendFourCC(entry.type)
        appendBigEndianUInt32(UInt32(entry.pngData.count + 8))
        data.append(entry.pngData)
    }

    try data.write(to: url)
}

let fullSizeIcon = drawIcon(size: 1024)
try writePNG(
    image: fullSizeIcon,
    to: resourcesURL.appendingPathComponent("OracleFreeAppIcon.png")
)

let icnsEntries: [(type: String, pixels: CGFloat)] = [
    ("icp4", 16),
    ("icp5", 32),
    ("icp6", 64),
    ("ic07", 128),
    ("ic08", 256),
    ("ic09", 512),
    ("ic10", 1024)
]
try writeICNS(
    entries: try icnsEntries.map { entry in
        (entry.type, try pngData(for: drawIcon(size: entry.pixels)))
    },
    to: resourcesURL.appendingPathComponent("OracleFreeAppIcon.icns")
)
