import AppKit

/// Watches left clicks system-wide. A click on a Dock icon that DockMinimize acts on is
/// swallowed (down, drags and up), so the Dock never sees it and cannot undo the action.
final class DockClickMonitor {
    private var tap: CFMachPort?
    private var swallowingClick = false

    func start() -> Bool {
        if tap != nil { return true }

        let types: [CGEventType] = [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        return true
    }

    fileprivate func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }

        case .leftMouseDown:
            swallowingClick = false
            // Any modifier key gives the normal Dock click (drag to reorder, Option-click, ...).
            let modifiers: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]
            if Preferences.shared.isEnabled, event.flags.intersection(modifiers).isEmpty, DockClickHandler.handle(at: event.location) {
                swallowingClick = true
                return nil
            }

        case .leftMouseDragged, .leftMouseUp:
            if swallowingClick {
                if type == .leftMouseUp { swallowingClick = false }
                return nil
            }

        default:
            break
        }
        return Unmanaged.passUnretained(event)
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let monitor = Unmanaged<DockClickMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    return monitor.handle(type, event)
}
