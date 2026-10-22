import AppKit

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)

let night = NSColor(red: 0.02, green: 0.04, blue: 0.11, alpha: 1)
let indigo = NSColor(red: 0.13, green: 0.11, blue: 0.36, alpha: 1)
let deepTeal = NSColor(red: 0.02, green: 0.17, blue: 0.22, alpha: 1)
let teal = NSColor(red: 0.30, green: 0.82, blue: 0.80, alpha: 1)
let periwinkle = NSColor(red: 0.42, green: 0.45, blue: 0.95, alpha: 1)
let violet = NSColor(red: 0.62, green: 0.38, blue: 0.92, alpha: 1)

func drawIcon(in context: CGContext, size: CGFloat) {
    let scale = size / 1024
    context.scaleBy(x: scale, y: scale)

    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    context.addPath(shape)
    context.setFillColor(night.cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(shape)
    context.clip()

    let background = CGGradient(colorsSpace: space, colors: [indigo.cgColor, night.cgColor, deepTeal.cgColor] as CFArray, locations: [0, 0.55, 1])!
    context.drawLinearGradient(background, start: CGPoint(x: body.minX, y: body.maxY), end: CGPoint(x: body.maxX, y: body.minY), options: [])

    let center = CGPoint(x: 512, y: 512)
    let glow = CGGradient(
        colorsSpace: space,
        colors: [
            teal.withAlphaComponent(0.95).cgColor,
            periwinkle.withAlphaComponent(0.75).cgColor,
            violet.withAlphaComponent(0.35).cgColor,
            violet.withAlphaComponent(0).cgColor,
        ] as CFArray,
        locations: [0, 0.35, 0.7, 1]
    )!
    context.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: 360, options: [])

    context.setStrokeColor(NSColor.white.withAlphaComponent(0.22).cgColor)
    context.setLineWidth(5)
    context.strokeEllipse(in: CGRect(x: center.x - 290, y: center.y - 290, width: 580, height: 580))
    context.restoreGState()

    let configuration = NSImage.SymbolConfiguration(pointSize: 250, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let eye = NSImage(systemSymbolName: "eye", accessibilityDescription: nil)?.withSymbolConfiguration(configuration) {
        let graphics = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        let origin = CGPoint(x: center.x - eye.size.width / 2, y: center.y - eye.size.height / 2)
        eye.draw(in: CGRect(origin: origin, size: eye.size))
        NSGraphicsContext.restoreGraphicsState()
    }
}

func writePNG(pixels: Int, to url: URL) throws {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    let context = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    drawIcon(in: context, size: CGFloat(pixels))
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    try writePNG(pixels: points, to: outputDirectory.appendingPathComponent("icon_\(points)x\(points).png"))
    try writePNG(pixels: points * 2, to: outputDirectory.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
