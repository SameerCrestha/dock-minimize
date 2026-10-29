// Renders the real settings window to PNGs for the README (light and dark).
// Run through scripts/screenshot.sh.
import AppKit
import SwiftUI

let outputDir = CommandLine.arguments[1]
NSApplication.shared.setActivationPolicy(.accessory)

let prefs = Preferences.shared
// Show the state a set-up user sees.
prefs.isTrusted = true
prefs.loginItemStatus = .enabled

func render(_ appearance: NSAppearance.Name, to name: String) {
    let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(prefs: prefs)))
    window.title = "DockMinimize"
    window.styleMask = [.titled, .closable, .miniaturizable]
    window.appearance = NSAppearance(named: appearance)
    window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
    // Switches only draw their "on" color in the key window of the active app.
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    RunLoop.main.run(until: Date().addingTimeInterval(0.6))

    guard let frameView = window.contentView?.superview else { fatalError("no frame view") }
    let size = frameView.bounds.size
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2), pixelsHigh: Int(size.height * 2),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = size
    frameView.cacheDisplay(in: frameView.bounds, to: rep)
    let url = URL(fileURLWithPath: outputDir).appendingPathComponent(name)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
    print("Wrote \(url.path)")
    window.close()
}

render(.aqua, to: "settings-light.png")
render(.darkAqua, to: "settings-dark.png")
exit(0)
