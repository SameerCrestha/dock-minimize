import AppKit
import ServiceManagement

/// Settings shared by the window and the click handler. Main thread only.
final class Preferences: ObservableObject {
    static let shared = Preferences()
    private let defaults = UserDefaults.standard

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: "enabled") }
    }

    /// Bundle IDs of apps whose Dock icon keeps its normal click.
    @Published var excludedBundleIDs: [String] {
        didSet { defaults.set(excludedBundleIDs, forKey: "excludedBundleIDs") }
    }

    @Published var isTrusted = Accessibility.isTrusted(prompt: false)
    @Published private(set) var loginItemStatus = SMAppService.mainApp.status
    @Published private(set) var loginItemError: String?

    private init() {
        defaults.register(defaults: ["enabled": true])
        isEnabled = defaults.bool(forKey: "enabled")
        excludedBundleIDs = defaults.stringArray(forKey: "excludedBundleIDs") ?? []
    }

    var launchesAtLogin: Bool { loginItemStatus == .enabled }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
        }
        loginItemStatus = SMAppService.mainApp.status
    }

    func isExcluded(_ app: NSRunningApplication) -> Bool {
        guard let bundleID = app.bundleIdentifier else { return false }
        return excludedBundleIDs.contains(bundleID)
    }

    func refresh() {
        isTrusted = Accessibility.isTrusted(prompt: false)
        loginItemStatus = SMAppService.mainApp.status
    }
}
