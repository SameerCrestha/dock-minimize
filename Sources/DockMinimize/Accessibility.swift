import AppKit
import ApplicationServices

enum Accessibility {
    static func isTrusted(prompt: Bool) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
}

extension AXUIElement {
    func attribute(_ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success else { return nil }
        return value
    }

    func string(_ name: String) -> String? { attribute(name) as? String }
    func bool(_ name: String) -> Bool? { attribute(name) as? Bool }
    func int(_ name: String) -> Int? { (attribute(name) as? NSNumber)?.intValue }
    func url(_ name: String) -> URL? { attribute(name) as? URL }
    func elements(_ name: String) -> [AXUIElement]? { attribute(name) as? [AXUIElement] }

    func isSettable(_ name: String) -> Bool {
        var settable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(self, name as CFString, &settable) == .success && settable.boolValue
    }
}
