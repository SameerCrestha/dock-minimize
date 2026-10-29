// Draws the DMG window background: an arrow from the app to Applications, and a caption.
//   swift scripts/dmg-background.swift out.png 2    (scale 1 or 2)
// Sizes and icon spots must match scripts/dmg-settings.py.
// Finder draws the icon labels white in Dark Mode and black in Light Mode,
// so the background is a mid blue that keeps both readable.
import AppKit

let args = CommandLine.arguments
guard args.count == 3, let scale = Double(args[2]) else {
  FileHandle.standardError.write("usage: dmg-background.swift out.png scale\n".data(using: .utf8)!)
  exit(1)
}
let size = CGSize(width: 600, height: 380)
let iconY: CGFloat = 170
let appX: CGFloat = 150
let applicationsX: CGFloat = 450

let ctx = CGContext(
  data: nil, width: Int(size.width * scale), height: Int(size.height * scale),
  bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// Top-left origin, like Finder icon positions.
ctx.scaleBy(x: scale, y: scale)
ctx.translateBy(x: 0, y: size.height)
ctx.scaleBy(x: 1, y: -1)
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)

func rgb(_ hex: Int, _ alpha: CGFloat = 1) -> NSColor {
  NSColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
          blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

// Background
let gradient = NSGradient(starting: rgb(0x4A8DF6), ending: rgb(0x2D63CF))!
gradient.draw(in: CGRect(origin: .zero, size: size), angle: 90)

// Soft light behind each icon
for x in [appX, applicationsX] {
  let glow = NSGradient(starting: rgb(0xFFFFFF, 0.16), ending: rgb(0xFFFFFF, 0))!
  glow.draw(fromCenter: CGPoint(x: x, y: iconY), radius: 0,
            toCenter: CGPoint(x: x, y: iconY), radius: 95, options: [])
}

// Arrow: a dotted trail and a chevron head
let white = rgb(0xFFFFFF, 0.92)
white.setStroke()
let startX = appX + 88, tipX = applicationsX - 88
let trail = NSBezierPath()
trail.move(to: CGPoint(x: startX, y: iconY))
trail.line(to: CGPoint(x: tipX - 14, y: iconY))
trail.lineWidth = 7
trail.lineCapStyle = .round
trail.setLineDash([0.1, 17], count: 2, phase: 0)
trail.stroke()

let head = NSBezierPath()
head.move(to: CGPoint(x: tipX - 20, y: iconY - 20))
head.line(to: CGPoint(x: tipX, y: iconY))
head.line(to: CGPoint(x: tipX - 20, y: iconY + 20))
head.lineWidth = 7
head.lineCapStyle = .round
head.lineJoinStyle = .round
head.stroke()

// Caption
func drawCentered(_ text: String, y: CGFloat, font: NSFont, color: NSColor) {
  let para = NSMutableParagraphStyle()
  para.alignment = .center
  let shadow = NSShadow()
  shadow.shadowColor = rgb(0x000000, 0.18)
  shadow.shadowOffset = CGSize(width: 0, height: -1)
  shadow.shadowBlurRadius = 2
  NSAttributedString(string: text, attributes: [
    .font: font, .foregroundColor: color, .paragraphStyle: para, .shadow: shadow,
  ]).draw(in: CGRect(x: 0, y: y, width: size.width, height: font.pointSize * 1.5))
}
drawCentered("Drag DockMinimize to Applications", y: 292,
             font: .systemFont(ofSize: 20, weight: .semibold), color: rgb(0xFFFFFF))
drawCentered("Then open it from your Applications folder.", y: 324,
             font: .systemFont(ofSize: 13, weight: .regular), color: rgb(0xFFFFFF, 0.85))

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
rep.size = size
try! rep.representation(using: .png, properties: [:])!
  .write(to: URL(fileURLWithPath: args[1]))
