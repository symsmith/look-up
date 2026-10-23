import AppKit
import LookUpCore

@MainActor
enum EyeIcon {
    private static let size = NSSize(width: 18, height: 18)
    private static let lineWidth: CGFloat = 1.5
    private static let lashLength: CGFloat = 2.2
    private static let lashPositions: [CGFloat] = [0.2, 0.5, 0.8]

    private static let images = Dictionary(uniqueKeysWithValues: StatusIcon.allCases.map { ($0, render($0)) })

    static func image(for icon: StatusIcon) -> NSImage {
        images[icon]!
    }

    static func render(_ icon: StatusIcon) -> NSImage {
        let image = NSImage(size: size, flipped: true) { _ in
            switch icon {
            case .open:
                drawOpenEye()
            case .closed:
                drawClosedEye()
            case .disabled:
                drawOpenEye()
                drawSlash()
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawOpenEye() {
        let upper = Lid(baseline: 10, bulge: -5.8)
        let lower = Lid(baseline: 10, bulge: 5.8)
        stroke(upper.path)
        stroke(lower.path)
        drawLashes(on: upper)
        NSBezierPath(ovalIn: NSRect(x: 6.6, y: 7.6, width: 4.8, height: 4.8)).fill()
    }

    private static func drawClosedEye() {
        let lid = Lid(baseline: 5.8, bulge: 5.8)
        stroke(lid.path)
        drawLashes(on: lid)
    }

    private static func drawLashes(on lid: Lid) {
        for t in lashPositions {
            let root = lid.point(at: t)
            let direction = lid.outward(at: t)
            let lash = NSBezierPath()
            lash.move(to: root)
            lash.line(to: CGPoint(x: root.x + direction.dx * lashLength, y: root.y + direction.dy * lashLength))
            stroke(lash)
        }
    }

    // The slash first erases a wider band so it stays readable where it crosses the eye.
    private static func drawSlash() {
        let slash = NSBezierPath()
        slash.move(to: CGPoint(x: 3, y: 2.5))
        slash.line(to: CGPoint(x: 15, y: 16))
        slash.lineCapStyle = .round
        NSGraphicsContext.current?.compositingOperation = .clear
        slash.lineWidth = lineWidth * 2.6
        slash.stroke()
        NSGraphicsContext.current?.compositingOperation = .sourceOver
        stroke(slash)
    }

    private static func stroke(_ path: NSBezierPath) {
        NSColor.black.set()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }
}

private struct Lid {
    let start: CGPoint
    let control1: CGPoint
    let control2: CGPoint
    let end: CGPoint
    let bulge: CGFloat

    init(baseline: CGFloat, bulge: CGFloat) {
        start = CGPoint(x: 2, y: baseline)
        control1 = CGPoint(x: 5.5, y: baseline + bulge)
        control2 = CGPoint(x: 12.5, y: baseline + bulge)
        end = CGPoint(x: 16, y: baseline)
        self.bulge = bulge
    }

    var path: NSBezierPath {
        let path = NSBezierPath()
        path.move(to: start)
        path.curve(to: end, controlPoint1: control1, controlPoint2: control2)
        return path
    }

    func point(at t: CGFloat) -> CGPoint {
        let u = 1 - t
        let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
        return CGPoint(
            x: a * start.x + b * control1.x + c * control2.x + d * end.x,
            y: a * start.y + b * control1.y + c * control2.y + d * end.y
        )
    }

    func outward(at t: CGFloat) -> CGVector {
        let u = 1 - t
        let dx = 3 * u * u * (control1.x - start.x) + 6 * u * t * (control2.x - control1.x) + 3 * t * t * (end.x - control2.x)
        let dy = 3 * u * u * (control1.y - start.y) + 6 * u * t * (control2.y - control1.y) + 3 * t * t * (end.y - control2.y)
        let length = (dx * dx + dy * dy).squareRoot()
        let normal = CGVector(dx: -dy / length, dy: dx / length)
        return (normal.dy > 0) == (bulge > 0) ? normal : CGVector(dx: -normal.dx, dy: -normal.dy)
    }
}
