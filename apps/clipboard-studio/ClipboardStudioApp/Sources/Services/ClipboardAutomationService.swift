import AppKit
import ApplicationServices
import Carbon
import Foundation

enum ClipboardAutomationService {
    struct CaptureResult {
        let text: String
        let captureMethodDescription: String
    }

    enum AutomationError: LocalizedError {
        case accessibilityRequired
        case noSelectionFound
        case noFocusedTextField
        case eventInjectionFailed

        var errorDescription: String? {
            switch self {
            case .accessibilityRequired:
                return "Accessibility permission is required for capture and direct send."
            case .noSelectionFound:
                return "No selected text was available in the target app."
            case .noFocusedTextField:
                return "The frontmost app does not appear to have a focused text field for direct send."
            case .eventInjectionFailed:
                return "The synthetic keyboard event could not be sent."
            }
        }
    }

    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func promptForTrust() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func captureSelection(from app: NSRunningApplication) async throws -> CaptureResult {
        guard isTrusted() else {
            throw AutomationError.accessibilityRequired
        }

        app.activate(options: [])
        try await pause(milliseconds: 120)

        if let selected = readSelectedText(from: app),
           !selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return CaptureResult(text: selected, captureMethodDescription: "Read the selected text")
        }

        let pasteboard = NSPasteboard.general
        let previousChangeCount = pasteboard.changeCount

        try pressCommandKey(keyCode: CGKeyCode(kVK_ANSI_C))

        for _ in 0..<10 {
            try await pause(milliseconds: 80)
            guard pasteboard.changeCount != previousChangeCount else { continue }
            if let text = pasteboard.string(forType: .string),
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return CaptureResult(text: text, captureMethodDescription: "Copied the current selection")
            }
        }

        throw AutomationError.noSelectionFound
    }

    static func pasteClipboardContents(into app: NSRunningApplication) async throws {
        guard isTrusted() else {
            throw AutomationError.accessibilityRequired
        }

        app.activate(options: [])
        try await pause(milliseconds: 140)

        guard hasFocusedTextInput(in: app) else {
            throw AutomationError.noFocusedTextField
        }

        try pressCommandKey(keyCode: CGKeyCode(kVK_ANSI_V))
    }

    private static func readSelectedText(from app: NSRunningApplication) -> String? {
        guard let focusedElement = focusedElement(in: app) else {
            return nil
        }

        if let selectedText = copyAttribute(kAXSelectedTextAttribute as CFString, from: focusedElement) as? String {
            let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : selectedText
        }

        if let selectedText = copyParameterizedText(from: focusedElement) {
            let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : selectedText
        }

        return nil
    }

    private static func hasFocusedTextInput(in app: NSRunningApplication) -> Bool {
        guard let focusedElement = focusedElement(in: app) else {
            return false
        }

        let attributeNames = copyAttributeNames(from: focusedElement)
        if attributeNames.contains(kAXSelectedTextRangeAttribute as String) ||
            attributeNames.contains(kAXNumberOfCharactersAttribute as String) ||
            attributeNames.contains(kAXValueAttribute as String) {
            return true
        }

        let textRoles: Set<String> = [
            kAXTextAreaRole as String,
            kAXTextFieldRole as String,
            "AXSearchField",
            kAXComboBoxRole as String,
            "AXWebArea"
        ]

        if let role = copyAttribute(kAXRoleAttribute as CFString, from: focusedElement) as? String {
            return textRoles.contains(role)
        }

        return false
    }

    private static func focusedElement(in app: NSRunningApplication) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        guard let focusedElementValue = copyAttribute(kAXFocusedUIElementAttribute as CFString, from: appElement) else {
            return nil
        }
        guard CFGetTypeID(focusedElementValue) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeDowncast(focusedElementValue, to: AXUIElement.self)
    }

    private static func copyParameterizedText(from element: AXUIElement) -> String? {
        guard let rangeValue = copyAttribute(kAXSelectedTextRangeAttribute as CFString, from: element) else {
            return nil
        }

        var selectedText: CFTypeRef?
        let result = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &selectedText
        )

        guard result == .success else { return nil }
        return selectedText as? String
    }

    private static func copyAttribute(_ attribute: CFString, from element: AXUIElement) -> AnyObject? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success else { return nil }
        return value as AnyObject?
    }

    private static func copyAttributeNames(from element: AXUIElement) -> [String] {
        var attributeNames: CFArray?
        let result = AXUIElementCopyAttributeNames(element, &attributeNames)
        guard result == .success, let attributeNames else { return [] }
        return attributeNames as? [String] ?? []
    }

    private static func pressCommandKey(keyCode: CGKeyCode) throws {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            throw AutomationError.eventInjectionFailed
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private static func pause(milliseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }
}
