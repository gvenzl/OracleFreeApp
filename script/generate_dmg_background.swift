#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate_dmg_background.swift <output.png>\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

let windowSize = NSSize(width: 640, height: 360)

guard let representation = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(windowSize.width),
    pixelsHigh: Int(windowSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("unable to create bitmap representation\n", stderr)
    exit(1)
}

func drawArrowHead(tip: NSPoint, tangentAngle: CGFloat, color: NSColor) {
    let length: CGFloat = 28
    let angle: CGFloat = .pi / 7
    let path = NSBezierPath()
    path.move(to: tip)
    path.line(to: NSPoint(
        x: tip.x - length * cos(tangentAngle - angle),
        y: tip.y - length * sin(tangentAngle - angle)
    ))
    path.move(to: tip)
    path.line(to: NSPoint(
        x: tip.x - length * cos(tangentAngle + angle),
        y: tip.y - length * sin(tangentAngle + angle)
    ))
    path.lineWidth = 8
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    color.setStroke()
    path.stroke()
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)

NSColor(calibratedRed: 0.97, green: 0.98, blue: 0.99, alpha: 1).setFill()
NSRect(origin: .zero, size: windowSize).fill()

let arrowColor = NSColor(calibratedRed: 0.08, green: 0.30, blue: 0.55, alpha: 1)
    .withAlphaComponent(0.42)
let start = NSPoint(x: 252, y: 194)
let control1 = NSPoint(x: 286, y: 272)
let control2 = NSPoint(x: 354, y: 272)
let end = NSPoint(x: 388, y: 194)

let arrowPath = NSBezierPath()
arrowPath.move(to: start)
arrowPath.curve(to: end, controlPoint1: control1, controlPoint2: control2)
arrowPath.lineWidth = 8
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
arrowColor.setStroke()
arrowPath.stroke()

let tangentAngle = atan2(end.y - control2.y, end.x - control2.x)
drawArrowHead(tip: end, tangentAngle: tangentAngle, color: arrowColor)

NSGraphicsContext.restoreGraphicsState()

guard let data = representation.representation(using: .png, properties: [:]) else {
    fputs("unable to render PNG data\n", stderr)
    exit(1)
}

try data.write(to: outputURL)
