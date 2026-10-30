// Draws docs/demo.gif for the README: the cursor clicks the Dock icon of the app in use and
// all its windows go down together, like the genie effect. A drawing, not a screen recording.
//   swift scripts/demo-gif.swift docs/demo.gif 1.5    (scale)
// Flat colors only: GIF has 256 colors per frame, and gradients turn into dither noise.
import AppKit
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 3, let scale = Double(args[2]) else {
  FileHandle.standardError.write("usage: demo-gif.swift out.gif scale\n".data(using: .utf8)!)
  exit(1)
}
let size = CGSize(width: 720, height: 450)
let frameTime = 0.04

func rgb(_ hex: Int, _ alpha: CGFloat = 1) -> NSColor {
  NSColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
          blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

func roundedRect(_ rect: CGRect, _ radius: CGFloat) -> NSBezierPath {
  NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

extension NSBezierPath {
  func fill(using color: NSColor) {
    color.setFill()
    fill()
  }
}

func smoothstep(_ from: Double, _ to: Double, _ x: Double) -> Double {
  let t = min(max((x - from) / (to - from), 0), 1)
  return t * t * (3 - 2 * t)
}

func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat { a + (b - a) * CGFloat(t) }

/// A bitmap context with a top-left origin, in points.
func makeContext(_ size: CGSize) -> CGContext {
  let ctx = CGContext(
    data: nil, width: Int((size.width * scale).rounded()), height: Int((size.height * scale).rounded()),
    bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.scaleBy(x: scale, y: scale)
  ctx.translateBy(x: 0, y: size.height)
  ctx.scaleBy(x: 1, y: -1)
  ctx.interpolationQuality = .high
  NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
  return ctx
}

/// CGContext draws images upside down in a flipped context, so flip them back.
func draw(_ image: CGImage, in rect: CGRect, _ ctx: CGContext) {
  ctx.saveGState()
  ctx.translateBy(x: rect.minX, y: rect.maxY)
  ctx.scaleBy(x: 1, y: -1)
  ctx.draw(image, in: CGRect(origin: .zero, size: rect.size))
  ctx.restoreGState()
}

func draw(_ text: String, in rect: CGRect, font: NSFont, color: NSColor,
          alignment: NSTextAlignment = .left) {
  let para = NSMutableParagraphStyle()
  para.alignment = alignment
  NSAttributedString(string: text, attributes: [
    .font: font, .foregroundColor: color, .paragraphStyle: para,
  ]).draw(in: rect)
}

// MARK: Scene

struct Window {
  let frame: CGRect
  let title: String
  let isKey: Bool
  let lines: [CGFloat]
  let checklist: Bool
}

let windows = [
  Window(frame: CGRect(x: 56, y: 58, width: 300, height: 205), title: "Ideas", isKey: false,
         lines: [240, 205, 250, 170, 230, 120], checklist: false),
  Window(frame: CGRect(x: 196, y: 104, width: 300, height: 205), title: "Draft", isKey: false,
         lines: [180, 150, 170, 120, 160, 90], checklist: false),
  Window(frame: CGRect(x: 376, y: 72, width: 288, height: 200), title: "To do", isKey: true,
         lines: [150, 120, 170, 100, 140], checklist: true),
]

let iconSize: CGFloat = 44
let iconGap: CGFloat = 8
let dockPadding: CGFloat = 10
let iconCount = 5
let activeIcon = 2
let dockWidth = CGFloat(iconCount) * iconSize + CGFloat(iconCount - 1) * iconGap + dockPadding * 2
let dock = CGRect(x: (size.width - dockWidth) / 2, y: 384, width: dockWidth, height: iconSize + 16)
func iconRect(_ i: Int) -> CGRect {
  CGRect(x: dock.minX + dockPadding + CGFloat(i) * (iconSize + iconGap), y: dock.minY + 8,
         width: iconSize, height: iconSize)
}
let target = iconRect(activeIcon)
// Where the windows land: the top of the app's Dock icon
let landY = target.minY + 12
let landLeft = target.midX - 15
let landRight = target.midX + 15

func drawWindowImage(_ w: Window) -> CGImage {
  let rect = CGRect(origin: .zero, size: w.frame.size)
  let ctx = makeContext(rect.size)
  roundedRect(rect, 10).addClip()
  rgb(0xFFFFFF).setFill()
  rect.fill()

  // Title bar, with the buttons in color only on the front window
  rgb(0xF2F2F4).setFill()
  CGRect(x: 0, y: 0, width: rect.width, height: 28).fill()
  rgb(0xDCDCE0).setFill()
  CGRect(x: 0, y: 28, width: rect.width, height: 1).fill()
  for (i, color) in [0xFF5F57, 0xFEBC2E, 0x28C840].enumerated() {
    NSBezierPath(ovalIn: CGRect(x: 10 + CGFloat(i) * 20, y: 8, width: 12, height: 12))
      .fill(using: rgb(w.isKey ? color : 0xD6D6DA))
  }
  draw(w.title, in: CGRect(x: 0, y: 6, width: rect.width, height: 18),
       font: .systemFont(ofSize: 12, weight: .semibold),
       color: rgb(w.isKey ? 0x3A3A3F : 0x9A9AA0), alignment: .center)

  // Content: a heading and lines of text, or a checklist
  if w.checklist {
    for (i, width) in w.lines.enumerated() {
      let y = 48 + CGFloat(i) * 28
      let box = NSBezierPath(ovalIn: CGRect(x: 18, y: y - 1, width: 14, height: 14))
      if i < 2 {
        box.fill(using: rgb(0xFF9F0A))
        let tick = NSBezierPath()
        tick.move(to: CGPoint(x: 21.5, y: y + 6))
        tick.line(to: CGPoint(x: 24, y: y + 8.5))
        tick.line(to: CGPoint(x: 28.5, y: y + 3.5))
        tick.lineWidth = 1.8
        tick.lineCapStyle = .round
        tick.lineJoinStyle = .round
        rgb(0xFFFFFF).setStroke()
        tick.stroke()
      } else {
        rgb(0xB8BCC4).setStroke()
        box.lineWidth = 1.4
        box.stroke()
      }
      roundedRect(CGRect(x: 42, y: y + 2, width: width, height: 8), 4)
        .fill(using: rgb(i < 2 ? 0xE3E5EA : 0xC9CCD3))
    }
  } else {
    roundedRect(CGRect(x: 18, y: 46, width: 120, height: 11), 5.5).fill(using: rgb(0x3A3A3F))
    for (i, width) in w.lines.enumerated() {
      roundedRect(CGRect(x: 18, y: 74 + CGFloat(i) * 19, width: width, height: 8), 4)
        .fill(using: rgb(0xD3D6DC))
    }
  }

  rgb(0x000000, 0.14).setStroke()
  let outline = roundedRect(rect.insetBy(dx: 0.5, dy: 0.5), 9.5)
  outline.lineWidth = 1
  outline.stroke()
  return ctx.makeImage()!
}

func drawIcon(_ i: Int, pressed: Bool) {
  let r = iconRect(i)
  let plate = roundedRect(r, 10)
  switch i {
  case 0:  // Files: a folder
    plate.fill(using: rgb(0x3D8BFF))
    roundedRect(CGRect(x: r.minX + 9, y: r.minY + 13, width: 12, height: 6), 2).fill(using: rgb(0xD6E8FF))
    roundedRect(CGRect(x: r.minX + 9, y: r.minY + 16, width: 26, height: 17), 3).fill(using: rgb(0xFFFFFF))
  case 1:  // Messages: a bubble
    plate.fill(using: rgb(0x34C759))
    NSBezierPath(ovalIn: CGRect(x: r.minX + 9, y: r.minY + 11, width: 26, height: 20)).fill(using: rgb(0xFFFFFF))
    let tail = NSBezierPath()
    tail.move(to: CGPoint(x: r.minX + 13, y: r.minY + 25))
    tail.line(to: CGPoint(x: r.minX + 11, y: r.minY + 34))
    tail.line(to: CGPoint(x: r.minX + 20, y: r.minY + 29))
    tail.fill(using: rgb(0xFFFFFF))
  case 2:  // Editor, the app in use: a page
    plate.fill(using: rgb(0xFF9F0A))
    roundedRect(CGRect(x: r.minX + 12, y: r.minY + 8, width: 20, height: 28), 3).fill(using: rgb(0xFFFFFF))
    for (j, width) in [12.0, 10, 12, 7].enumerated() {
      roundedRect(CGRect(x: r.minX + 16, y: r.minY + 14 + CGFloat(j) * 5, width: width, height: 2), 1)
        .fill(using: rgb(0xFFC56B))
    }
  case 3:  // Calendar
    plate.fill(using: rgb(0xFFFFFF))
    NSGraphicsContext.current!.saveGraphicsState()
    plate.addClip()
    rgb(0xFF3B30).setFill()
    CGRect(x: r.minX, y: r.minY, width: r.width, height: 13).fill()
    NSGraphicsContext.current!.restoreGraphicsState()
    draw("30", in: CGRect(x: r.minX, y: r.minY + 13, width: r.width, height: 28),
         font: .systemFont(ofSize: 21, weight: .medium), color: rgb(0x1D1D1F), alignment: .center)
  default:  // Settings: a gear
    plate.fill(using: rgb(0x8E8E93))
    let center = CGPoint(x: r.midX, y: r.midY)
    rgb(0xFFFFFF).setFill()
    for k in 0..<8 {
      let tooth = NSBezierPath(roundedRect: CGRect(x: -3, y: -15, width: 6, height: 8), xRadius: 1.5, yRadius: 1.5)
      var transform = AffineTransform(translationByX: center.x, byY: center.y)
      transform.rotate(byDegrees: CGFloat(k) * 45)
      tooth.transform(using: transform)
      tooth.fill()
    }
    NSBezierPath(ovalIn: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)).fill()
    NSBezierPath(ovalIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)).fill(using: rgb(0x8E8E93))
  }
  if pressed {
    plate.fill(using: rgb(0x000000, 0.3))
  }
}

func drawBackground() {
  rgb(0x3D7AE5).setFill()
  CGRect(origin: .zero, size: size).fill()
  NSBezierPath(ovalIn: CGRect(x: -220, y: 170, width: 620, height: 620)).fill(using: rgb(0x4B88EF))
  NSBezierPath(ovalIn: CGRect(x: 420, y: -260, width: 540, height: 540)).fill(using: rgb(0x336FDB))

  // Menu bar of the app in use
  rgb(0xFFFFFF, 0.2).setFill()
  CGRect(x: 0, y: 0, width: size.width, height: 24).fill()
  draw("Editor", in: CGRect(x: 16, y: 4, width: 60, height: 18),
       font: .systemFont(ofSize: 13, weight: .bold), color: rgb(0xFFFFFF))
  draw("File      Edit      Format      View      Window      Help", in: CGRect(x: 78, y: 4, width: 400, height: 18),
       font: .systemFont(ofSize: 13), color: rgb(0xFFFFFF))
  draw("Fri 9:41", in: CGRect(x: size.width - 116, y: 4, width: 100, height: 18),
       font: .systemFont(ofSize: 13, weight: .medium), color: rgb(0xFFFFFF), alignment: .right)
}

func drawDock(pressed: Bool) {
  let shape = roundedRect(dock, 16)
  shape.fill(using: rgb(0xFFFFFF, 0.32))
  rgb(0xFFFFFF, 0.5).setStroke()
  shape.lineWidth = 1
  shape.stroke()
  for i in 0..<iconCount {
    drawIcon(i, pressed: pressed && i == activeIcon)
  }
  // Running apps: Files and Editor
  for i in [0, activeIcon] {
    let r = iconRect(i)
    NSBezierPath(ovalIn: CGRect(x: r.midX - 2, y: dock.maxY - 6, width: 4, height: 4)).fill(using: rgb(0x1D1D1F, 0.75))
  }
}

func drawWindow(_ w: Window, _ image: CGImage, genie t: Double, alpha: CGFloat, _ ctx: CGContext) {
  let r = w.frame
  ctx.saveGState()
  ctx.setAlpha(alpha)
  if t <= 0 {
    // Shadow offsets ignore the flip and the scale
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8 * scale), blur: 22 * scale,
                  color: rgb(0x0A2A6B, 0.35).cgColor)
    roundedRect(r, 10).fill(using: rgb(0xFFFFFF))
    ctx.restoreGState()
    draw(image, in: r, ctx)
    ctx.restoreGState()
    return
  }

  // Genie: the bottom stretches down and narrows into the icon, then the window slides in.
  // Drawn in thin rows down the screen, each one picking its line of the window and its width.
  let bend = smoothstep(0, 0.45, t)
  let slide = CGFloat(smoothstep(0.2, 1, t)) * (landY - r.minY)
  let height = lerp(r.height, landY - r.minY, bend)
  let top = r.minY + slide
  let step: CGFloat = 0.5
  var y = top
  while y < min(top + height, landY) {
    let line = min(Int((y - top) / height * CGFloat(image.height)), image.height - 1)
    let narrow = bend * smoothstep(Double(r.minY + (landY - r.minY) * 0.15), Double(landY), Double(y))
    let left = lerp(r.minX, landLeft, narrow)
    let right = lerp(r.maxX, landRight, narrow)
    let row = image.cropping(to: CGRect(x: 0, y: line, width: image.width, height: 1))!
    // A little overlap so the rows leave no gaps
    draw(row, in: CGRect(x: left, y: y, width: right - left, height: step + 0.4), ctx)
    y += step
  }
  ctx.restoreGState()
}

func drawCursor(at p: CGPoint) {
  let points: [(CGFloat, CGFloat)] = [(0, 0), (0, 17), (4, 13.2), (6.9, 19.8), (9.6, 18.7), (6.8, 12.3), (12.4, 12.3)]
  let arrow = NSBezierPath()
  arrow.move(to: CGPoint(x: p.x + points[0].0, y: p.y + points[0].1))
  for (x, y) in points.dropFirst() {
    arrow.line(to: CGPoint(x: p.x + x, y: p.y + y))
  }
  arrow.close()
  arrow.lineJoinStyle = .round
  arrow.lineWidth = 2.6
  rgb(0xFFFFFF).setStroke()
  arrow.stroke()
  arrow.fill(using: rgb(0x000000))
}

func drawClick(at p: CGPoint, progress: Double) {
  guard progress > 0, progress < 1 else { return }
  let radius = 5 + 17 * CGFloat(progress)
  let ring = NSBezierPath(ovalIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
  ring.lineWidth = 2.5
  rgb(0x1D1D1F, 0.6 * (1 - CGFloat(progress))).setStroke()
  ring.stroke()
}

// MARK: Timeline

struct Frame {
  var cursor: CGPoint
  var pressed = false
  var click = 0.0
  var genie = 0.0
  var windowAlpha: CGFloat = 1
  var duration = frameTime
}

let windowImages = windows.map(drawWindowImage)

func render(_ f: Frame) -> CGImage {
  let ctx = makeContext(size)
  drawBackground()
  drawDock(pressed: f.pressed)
  for (w, image) in zip(windows, windowImages) where f.windowAlpha > 0 {
    drawWindow(w, image, genie: f.genie, alpha: f.windowAlpha, ctx)
  }
  drawClick(at: f.cursor, progress: f.click)
  drawCursor(at: f.cursor)
  return ctx.makeImage()!
}

let start = CGPoint(x: 540, y: 196)
let click = CGPoint(x: target.midX + 2, y: target.midY + 2)
func path(_ t: Double, from a: CGPoint, to b: CGPoint) -> CGPoint {
  // A gentle curve, the way a hand moves a mouse
  let s = CGFloat(smoothstep(0, 1, t))
  let control = CGPoint(x: (a.x + b.x) / 2 + 60, y: (a.y + b.y) / 2 + 40)
  let x = (1 - s) * (1 - s) * a.x + 2 * (1 - s) * s * control.x + s * s * b.x
  let y = (1 - s) * (1 - s) * a.y + 2 * (1 - s) * s * control.y + s * s * b.y
  return CGPoint(x: x, y: y)
}

var frames: [Frame] = []
frames.append(Frame(cursor: start, duration: 0.8))
let moveFrames = 24
for i in 1...moveFrames {
  frames.append(Frame(cursor: path(Double(i) / Double(moveFrames), from: start, to: click)))
}
let pressFrames = 4
let genieFrames = 16
let clickFrames = 12
for i in 0..<(pressFrames + genieFrames) {
  let genie = i < pressFrames ? 0 : Double(i - pressFrames + 1) / Double(genieFrames)
  frames.append(Frame(cursor: click, pressed: i < pressFrames,
                      click: i < clickFrames ? Double(i + 1) / Double(clickFrames) : 0,
                      genie: genie))
}
frames.append(Frame(cursor: click, genie: 1, duration: 1.6))
// Back to the start, for the loop
let resetFrames = 14
for i in 1...resetFrames {
  let t = Double(i) / Double(resetFrames)
  frames.append(Frame(cursor: path(t, from: click, to: start), windowAlpha: CGFloat(smoothstep(0.3, 1, t))))
}

let url = URL(fileURLWithPath: args[1])
let gif = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames.count, nil)!
CGImageDestinationSetProperties(gif, [
  kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0],
] as CFDictionary)
for f in frames {
  CGImageDestinationAddImage(gif, render(f), [
    kCGImagePropertyGIFDictionary: [
      kCGImagePropertyGIFDelayTime: f.duration,
      kCGImagePropertyGIFUnclampedDelayTime: f.duration,
    ],
  ] as CFDictionary)
}
guard CGImageDestinationFinalize(gif) else {
  FileHandle.standardError.write("could not write \(url.path)\n".data(using: .utf8)!)
  exit(1)
}
