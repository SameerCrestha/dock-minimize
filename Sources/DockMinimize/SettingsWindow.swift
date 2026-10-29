import AppKit
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show() {
        Preferences.shared.refresh()
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(prefs: .shared)))
            window.title = "DockMinimize"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
        }
        // While the window is open the app gets a Dock icon and a menu bar, so it is easy to find.
        NSApp.setActivationPolicy(.regular)
        window?.makeKeyAndOrderFront(nil)
        if #available(macOS 14, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
    }

    var isVisible: Bool { window.map { $0.isVisible || $0.isMiniaturized } ?? false }

    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

struct SettingsView: View {
    @ObservedObject var prefs: Preferences

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "dock.arrow.down.rectangle")
                        .font(.system(size: 34))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DockMinimize").font(.title2.bold())
                        Text("Click the Dock icon of the app in front to minimize all its windows.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Access") {
                if prefs.isTrusted {
                    Label("Accessibility access is on", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Needs Accessibility access to see Dock clicks and minimize windows.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Already switched on? After an update macOS keeps the old entry. Select DockMinimize, click −, then + to add it again.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Open Accessibility Settings") { Accessibility.openSettings() }
                }
            }

            Section("General") {
                Toggle("Minimize on Dock click", isOn: $prefs.isEnabled)
                Toggle("Launch at login", isOn: Binding(
                    get: { prefs.launchesAtLogin },
                    set: { prefs.setLaunchAtLogin($0) }
                ))
                if prefs.loginItemStatus == .requiresApproval {
                    HStack {
                        Text("Approve DockMinimize in Login Items.").foregroundStyle(.secondary)
                        Spacer()
                        Button("Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
                    }
                }
                if let error = prefs.loginItemError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            Section {
                if prefs.excludedBundleIDs.isEmpty {
                    Text("None").foregroundStyle(.secondary)
                }
                ForEach(prefs.excludedBundleIDs, id: \.self) { bundleID in
                    HStack {
                        Image(nsImage: AppInfo.icon(bundleID))
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(AppInfo.name(bundleID))
                        Spacer()
                        Button {
                            prefs.excludedBundleIDs.removeAll { $0 == bundleID }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove")
                    }
                }
                Button("Add App…", action: addApps)
            } header: {
                Text("Excluded apps")
            } footer: {
                Text("A Dock click on these apps works as usual.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Text("Closing this window keeps DockMinimize working. Open it again to come back here.")
                    .foregroundStyle(.secondary)
                HStack {
                    Text("Quit closes DockMinimize and stops it completely. It starts again when you open it, or at login.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Quit DockMinimize") {
                        AppDelegate.quitRequested = true
                        NSApp.terminate(nil)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 670)
    }

    private func addApps() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Exclude"
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            guard let bundleID = Bundle(url: url)?.bundleIdentifier,
                  !prefs.excludedBundleIDs.contains(bundleID) else { continue }
            prefs.excludedBundleIDs.append(bundleID)
        }
    }
}

private enum AppInfo {
    static func url(_ bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    static func name(_ bundleID: String) -> String {
        url(bundleID)?.deletingPathExtension().lastPathComponent ?? bundleID
    }

    static func icon(_ bundleID: String) -> NSImage {
        url(bundleID).map { NSWorkspace.shared.icon(forFile: $0.path) } ?? NSWorkspace.shared.icon(for: .application)
    }
}
