import CoreGraphics
import Foundation

enum Keyboard {
    private static let fnKeyCode: CGKeyCode = 0x3F
    private static let returnKeyCode: CGKeyCode = 0x24
    private static let escapeKeyCode: CGKeyCode = 0x35
    private static let src = CGEventSource(stateID: .hidSystemState)

    // Fn is a modifier: it generates flagsChanged, not keyDown/keyUp.
    static func fnDown() {
        guard let ev = CGEvent(source: src) else { return }
        ev.type = .flagsChanged
        ev.setIntegerValueField(.keyboardEventKeycode, value: Int64(fnKeyCode))
        ev.flags = .maskSecondaryFn
        ev.post(tap: .cghidEventTap)
    }

    static func fnUp() {
        guard let ev = CGEvent(source: src) else { return }
        ev.type = .flagsChanged
        ev.setIntegerValueField(.keyboardEventKeycode, value: Int64(fnKeyCode))
        ev.flags = []
        ev.post(tap: .cghidEventTap)
    }

    static func tapFn() {
        fnDown()
        usleep(30_000)
        fnUp()
    }

    static func tapReturn() {
        tapKey(returnKeyCode)
    }

    static func tapEscape() {
        tapKey(escapeKeyCode)
    }

    private static let aKeyCode: CGKeyCode = 0x00
    private static let cKeyCode: CGKeyCode = 0x08
    private static let vKeyCode: CGKeyCode = 0x09

    static func tapCmdA() { tapKey(aKeyCode, flags: .maskCommand) }
    static func tapCmdC() { tapKey(cKeyCode, flags: .maskCommand) }
    static func tapCmdV() { tapKey(vKeyCode, flags: .maskCommand) }

    private static func tapKey(_ code: CGKeyCode, flags: CGEventFlags = []) {
        guard
            let down = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: true),
            let up = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: false)
        else { return }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
