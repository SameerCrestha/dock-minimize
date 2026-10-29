import AppKit
import ApplicationServices
import os

private let log = Logger(subsystem: "io.github.sameercrestha.dockminimize", category: "dock-click")

enum DockClickHandler {
    /// Runs on mouse down. Returns true when it acted, so the click must not reach the Dock.
    ///
    /// - App in front with open windows: minimize all of them.
    /// - Anything else (including bringing minimized windows back): the Dock handles the click as usual.
    static func handle(at point: CGPoint) -> Bool {
        guard let app = DockHitTest.runningApp(at: point),
              !app.isHidden,
              app.processIdentifier != NSRunningApplication.current.processIdentifier
        else { return false }
        let name = app.localizedName ?? "app"
        if Preferences.shared.isExcluded(app) {
            log.notice("\(name, privacy: .public): excluded, Dock handles the click")
            return false
        }

        guard let windows = AppWindows.list(pid: app.processIdentifier) else {
            log.notice("\(name, privacy: .public): could not read windows, Dock handles the click")
            return false
        }
        let open = windows.filter { !$0.isMinimized }
        let minimized = windows.filter(\.isMinimized)
        let isFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
        let state = "front=\(isFrontmost) open=\(open.count) minimized=\(minimized.count)"

        if isFrontmost, !open.isEmpty {
            log.notice("\(name, privacy: .public): \(state, privacy: .public) -> minimize")
            WindowActions.minimize(open, of: app)
            return true
        }
        log.notice("\(name, privacy: .public): \(state, privacy: .public) -> Dock handles the click")
        return false
    }
}

enum DockHitTest {
    /// The running app whose Dock icon is under the point, or nil.
    static func runningApp(at point: CGPoint) -> NSRunningApplication? {
        guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else { return nil }

        // Hit-testing the Dock's own element only asks the Dock, never the app under the pointer.
        let dockElement = AXUIElementCreateApplication(dock.processIdentifier)
        var hit: AXUIElement?
        guard AXUIElementCopyElementAtPosition(dockElement, Float(point.x), Float(point.y), &hit) == .success,
              let item = hit,
              item.string(kAXRoleAttribute) == "AXDockItem",
              item.string(kAXSubroleAttribute) == "AXApplicationDockItem",
              let url = item.url(kAXURLAttribute)
        else { return nil }

        let apps = NSWorkspace.shared.runningApplications
        let path = url.standardizedFileURL.path
        if let app = apps.first(where: { $0.bundleURL?.standardizedFileURL.path == path }) { return app }
        guard let bundleID = Bundle(url: url)?.bundleIdentifier else { return nil }
        return apps.first { $0.bundleIdentifier == bundleID }
    }
}

struct AppWindow {
    let element: AXUIElement
    let isMinimized: Bool
}

enum AppWindows {
    /// Standard windows of the app that can be minimized. Nil when the app does not answer.
    static func list(pid: pid_t) -> [AppWindow]? {
        guard let windows = AXUIElementCreateApplication(pid).elements(kAXWindowsAttribute) else { return nil }
        return windows.compactMap { window in
            // Some apps (Safari, settings windows) use AXDialog for normal windows.
            let subrole = window.string(kAXSubroleAttribute)
            guard subrole == kAXStandardWindowSubrole || subrole == kAXDialogSubrole,
                  window.bool("AXFullScreen") != true,
                  window.isSettable(kAXMinimizedAttribute),
                  let isMinimized = window.bool(kAXMinimizedAttribute)
            else { return nil }
            return AppWindow(element: window, isMinimized: isMinimized)
        }
    }
}

enum WindowActions {
    /// Two or more windows: the app's own Minimize All (⌥⌘M), which animates every window
    /// together. Windows it missed (apps without Minimize All) are then minimized one by one.
    static func minimize(_ windows: [AppWindow], of app: NSRunningApplication) {
        let elements = windows.map(\.element)
        let pid = app.processIdentifier
        let appName = app.localizedName ?? "app"
        DispatchQueue.global(qos: .userInteractive).async {
            guard elements.count > 1, triggerMinimizeAll(pid: pid, appName: appName) else {
                minimizeEach(elements, appName: appName)
                return
            }
            Thread.sleep(forTimeInterval: 0.6)
            let missed = elements.filter { $0.bool(kAXMinimizedAttribute) == false }
            if !missed.isEmpty {
                log.notice("\(appName, privacy: .public): Minimize All missed \(missed.count) windows")
                minimizeEach(missed, appName: appName)
            }
        }
    }

    /// Presses the app's Minimize All menu item, or sends ⌥⌘M when only the plain Minimize (⌘M)
    /// is visible, since Minimize All is its hidden Option variant. False when the app has neither.
    private static func triggerMinimizeAll(pid: pid_t, appName: String) -> Bool {
        let items = minimizeMenuItems(pid: pid)
        if let minimizeAll = items.all {
            AXUIElementSetMessagingTimeout(minimizeAll, 0.15)
            let result = AXUIElementPerformAction(minimizeAll, kAXPressAction as CFString)
            log.notice("\(appName, privacy: .public): pressed Minimize All, AX result \(result.rawValue)")
            return result == .success || result == .cannotComplete
        }
        guard items.minimize else { return false }
        let source = CGEventSource(stateID: .hidSystemState)
        for keyDown in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: 46, keyDown: keyDown) else { return false }
            event.flags = [.maskCommand, .maskAlternate]
            event.postToPid(pid)
        }
        log.notice("\(appName, privacy: .public): sent Option-Command-M")
        return true
    }

    /// Looks through the menu bar (from the end, where the Window menu sits) for ⌥⌘M and ⌘M items.
    private static func minimizeMenuItems(pid: pid_t) -> (all: AXUIElement?, minimize: Bool) {
        guard let bar = AXUIElementCreateApplication(pid).attribute(kAXMenuBarAttribute) else { return (nil, false) }
        let menuBar = bar as! AXUIElement
        for barItem in (menuBar.elements(kAXChildrenAttribute) ?? []).reversed() {
            for menu in barItem.elements(kAXChildrenAttribute) ?? [] {
                var all: AXUIElement?
                var minimize = false
                for item in menu.elements(kAXChildrenAttribute) ?? [] where item.string(kAXMenuItemCmdCharAttribute)?.uppercased() == "M" {
                    // AX modifier bits: 0 = Command only, 2 = Option + Command.
                    switch item.int(kAXMenuItemCmdModifiersAttribute) {
                    case 0: minimize = true
                    case 2: all = item
                    default: break
                    }
                }
                if minimize || all != nil { return (all, minimize) }
            }
        }
        return (nil, false)
    }

    /// Sends every window its own minimize request.
    private static func minimizeEach(_ windows: [AXUIElement], appName: String) {
        DispatchQueue.concurrentPerform(iterations: windows.count) { i in
            AXUIElementSetAttributeValue(windows[i], kAXMinimizedAttribute as CFString, kCFBooleanTrue)
        }
        log.notice("\(appName, privacy: .public): minimized \(windows.count) windows by AX")
    }
}
