// Draws the app icon: a window shrinking into the Dock, on the DMG's blue.
// Run it after changing the design, and commit Resources/AppIcon.icns:
//   swift scripts/app-icon.swift build/AppIcon.iconset
//   iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns
// The shape follows Apple's macOS icon grid: an 824pt rounded square on a 1024pt canvas.
import AppKit

let args = CommandLine.arguments
guard args.count == 2 else {
  FileHandle.standardError.write("usage: app-icon.swift out.iconset\n".data(using: .utf8)!)
  exit(1)
}
let iconset = URL(fileURLWithPath: args[1])
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func rgb(_ hex: Int, _ alpha: CGFloat = 1) -> NSColor {
  NSColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
          blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

func roundedRect(_ rect: CGRect, _ radius: CGFloat) -> NSBezierPath {
  NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func draw(pixels: Int) -> Data {
  let scale = CGFloat(pixels) / 1024
  let ctx = CGContext(
    data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  // Top-left origin, in points of the 1024 canvas.
  ctx.scaleBy(x: scale, y: scale)
  ctx.translateBy(x: 0, y: 1024)
  ctx.scaleBy(x: 1, y: -1)
  NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)

  // Plate, with Apple's drop shadow (shadow offsets ignore the flip and the scale)
  let plate = roundedRect(CGRect(x: 100, y: 100, width: 824, height: 824), 185)
  ctx.saveGState()
  ctx.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 20 * scale,
                color: rgb(0x000000, 0.3).cgColor)
  rgb(0x2D63CF).setFill()
  plate.fill()
  ctx.restoreGState()
  ctx.saveGState()
  plate.addClip()
  NSGradient(starting: rgb(0x5A9BFA), ending: rgb(0x2457C2))!
    .draw(in: CGRect(x: 100, y: 100, width: 824, height: 824), angle: 90)
  ctx.restoreGState()

  // Dock: a frosted bar with three icons
  let dockIcons: [CGFloat] = [326, 482, 638]
  roundedRect(CGRect(x: 232, y: 742, width: 560, height: 92), 30).fill(using: rgb(0xFFFFFF, 0.24))
  for x in dockIcons {
    // The right one catches the window, in the color the window fades to
    let color = x == dockIcons[2] ? rgb(0xCFE0FF) : rgb(0xFFFFFF, 0.45)
    roundedRect(CGRect(x: x, y: 760, width: 60, height: 60), 15).fill(using: color)
  }

  // Window, bending down into the right Dock icon like the genie effect
  let left: CGFloat = 196, right: CGFloat = 616, top: CGFloat = 196, corner: CGFloat = 28
  let landLeft = dockIcons[2], landRight = dockIcons[2] + 60, landY: CGFloat = 776
  let genie = NSBezierPath()
  genie.move(to: CGPoint(x: left + corner, y: top))
  genie.line(to: CGPoint(x: right - corner, y: top))
  genie.curve(to: CGPoint(x: right, y: top + corner),
              controlPoint1: CGPoint(x: right - corner / 2, y: top),
              controlPoint2: CGPoint(x: right, y: top + corner / 2))
  genie.line(to: CGPoint(x: right, y: 380))
  genie.curve(to: CGPoint(x: landRight, y: landY), controlPoint1: CGPoint(x: right, y: 560),
              controlPoint2: CGPoint(x: landRight, y: 600))
  genie.line(to: CGPoint(x: landLeft, y: landY))
  genie.curve(to: CGPoint(x: left, y: 380), controlPoint1: CGPoint(x: landLeft, y: 620),
              controlPoint2: CGPoint(x: left, y: 560))
  genie.line(to: CGPoint(x: left, y: top + corner))
  genie.curve(to: CGPoint(x: left + corner, y: top),
              controlPoint1: CGPoint(x: left, y: top + corner / 2),
              controlPoint2: CGPoint(x: left + corner / 2, y: top))
  genie.close()
  ctx.saveGState()
  ctx.setShadow(offset: CGSize(width: 0, height: -8 * scale), blur: 24 * scale,
                color: rgb(0x0A2A6B, 0.35).cgColor)
  rgb(0xFFFFFF).setFill()
  genie.fill()
  ctx.restoreGState()
  ctx.saveGState()
  genie.addClip()
  NSGradient(starting: rgb(0xFFFFFF), ending: rgb(0xCFE0FF))!
    .draw(in: CGRect(x: left, y: top, width: landRight - left, height: landY - top), angle: 90)
  ctx.restoreGState()

  // Title bar buttons, the yellow one being the minimize button, and two lines of content
  for (x, color) in [(left + 40, 0xFF5F57), (left + 78, 0xFEBC2E), (left + 116, 0x28C840)] {
    NSBezierPath(ovalIn: CGRect(x: x - 12, y: top + 28, width: 24, height: 24)).fill(using: rgb(color))
  }
  for (y, width) in [(top + 94, 300.0), (top + 136, 220.0)] {
    roundedRect(CGRect(x: left + 40, y: y, width: width, height: 18), 9).fill(using: rgb(0xC5D7F5))
  }

  let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
  return rep.representation(using: .png, properties: [:])!
}

extension NSBezierPath {
  func fill(using color: NSColor) {
    color.setFill()
    fill()
  }
}

for points in [16, 32, 128, 256, 512] {
  try! draw(pixels: points).write(to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
  try! draw(pixels: points * 2).write(to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
