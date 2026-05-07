import AppKit
import Foundation

public enum OracleFreeAppIconResource {
    public static var image: NSImage? {
        guard let url = Bundle.module.url(forResource: "OracleFreeAppIcon", withExtension: "png") else {
            return nil
        }

        return NSImage(contentsOf: url)
    }

    public static func menuBarImage(size: CGFloat = 16) -> NSImage? {
        guard let sourceImage = image else {
            return nil
        }

        let targetSize = NSSize(width: size, height: size)
        let targetImage = NSImage(size: targetSize)
        targetImage.lockFocus()
        sourceImage.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: sourceImage.size),
            operation: .copy,
            fraction: 1
        )
        targetImage.unlockFocus()
        targetImage.isTemplate = false

        return targetImage
    }
}
