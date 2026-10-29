import AppKit
import os

private let log = Logger(subsystem: "io.github.sameercrestha.dockminimize", category: "app")

/// Runs in the background with no menu bar icon. Opening the app again shows the settings window.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = DockClickMonitor()
    private let settingsWindow = SettingsWindowController()
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A hung app must not freeze clicks for long, so every AX call gives up quickly.
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.3)

        setUpMainMenu()
        Preferences.shared.enableLaunchAtLoginOnFirstRun()
        if Accessibility.isTrusted(prompt: true) {
            startMonitor()
        } else {
            waitForAccessibility()
        }

        Updater.shared.onNotificationClick = { [weak self] in self?.settingsWindow.show() }
        Updater.shared.startDailyChecks()

        // At login and after an update it starts quietly. Any other launch shows the window,
        // so whoever opened it sees it.
        let quietLaunch = launchedAsLoginItem || CommandLine.arguments.contains("--updated")
        if !quietLaunch || !Preferences.shared.isTrusted {
            settingsWindow.show()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow.show()
        return false
    }

    /// Set by the Quit button in the window, the only way to really stop DockMinimize.
    static var quitRequested = false

    /// ⌘Q and Quit in the Dock are easy to press by habit while the window is open,
    /// so they only close the window and DockMinimize keeps working.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard settingsWindow.isVisible, !AppDelegate.quitRequested, !isSystemQuit else { return .terminateNow }
        settingsWindow.close()
        return .terminateCancel
    }

    /// Log out, restart and shut down send a quit event with a reason. Those must go through.
    private var isSystemQuit: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventClass == fourCharCode("aevt"),
              event.eventID == fourCharCode("quit")
        else { return false }
        return event.attributeDescriptor(forKeyword: fourCharCode("why?")) != nil
    }

    private var launchedAsLoginItem: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == fourCharCode("oapp")
        else { return false }
        return event.paramDescriptor(forKeyword: fourCharCode("prdt"))?.enumCodeValue == fourCharCode("lgit")
    }

    /// Only shown while the settings window is open.
    private func setUpMainMenu() {
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit DockMinimize", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")

        let mainMenu = NSMenu()
        for submenu in [appMenu, windowMenu] {
            let item = NSMenuItem()
            item.submenu = submenu
            mainMenu.addItem(item)
        }
        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
    }

    // MARK: Permission

    private func startMonitor() {
        Preferences.shared.isTrusted = true
        if monitor.start() {
            log.notice("watching Dock clicks")
        } else {
            log.error("could not create the event tap, waiting for Accessibility access")
            waitForAccessibility()
        }
    }

    private func waitForAccessibility() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard Accessibility.isTrusted(prompt: false) else { return }
            timer.invalidate()
            self?.startMonitor()
        }
    }
}

private func fourCharCode(_ code: String) -> UInt32 {
    code.utf8.reduce(0) { $0 << 8 | UInt32($1) }
}
