import AppKit
import ServiceManagement
import os

private let log = Logger(subsystem: "io.github.sameercrestha.dockminimize", category: "app")

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let monitor = DockClickMonitor()
    private var statusItem: NSStatusItem?
    private var permissionTimer: Timer?

    private lazy var enabledItem = menuItem("Enabled", #selector(toggleEnabled))
    private lazy var permissionItem = menuItem("Grant Accessibility Access…", #selector(openAccessibilitySettings))
    private lazy var loginItem = menuItem("Launch at Login", #selector(toggleLaunchAtLogin))

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["enabled": true])
        monitor.isEnabled = UserDefaults.standard.bool(forKey: "enabled")

        // A hung app must not freeze clicks for long, so every AX call gives up quickly.
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.3)

        setUpStatusItem()
        if Accessibility.isTrusted(prompt: true) {
            startMonitor()
        } else {
            waitForAccessibility()
        }
    }

    // MARK: Menu

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "dock.arrow.down.rectangle", accessibilityDescription: "DockMinimize")

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(withTitle: "DockMinimize \(version)", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(enabledItem)
        menu.addItem(permissionItem)
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit DockMinimize", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        enabledItem.state = monitor.isEnabled ? .on : .off
        permissionItem.isHidden = Accessibility.isTrusted(prompt: false)
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    private func menuItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func toggleEnabled() {
        monitor.isEnabled.toggle()
        UserDefaults.standard.set(monitor.isEnabled, forKey: "enabled")
    }

    @objc private func openAccessibilitySettings() {
        Accessibility.openSettings()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            if #available(macOS 14, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
            NSAlert(error: error).runModal()
        }
    }

    // MARK: Permission

    private func startMonitor() {
        if monitor.start() {
            log.info("watching Dock clicks")
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
