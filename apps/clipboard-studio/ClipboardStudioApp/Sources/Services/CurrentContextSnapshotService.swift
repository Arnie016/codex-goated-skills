import AppKit
import Foundation

enum CurrentContextSnapshotService {
    private struct BrowserPageContext {
        let title: String?
        let urlString: String?
    }

    static func captureSnapshot(
        from app: NSRunningApplication,
        preferredSelection: String? = nil
    ) -> FocusSnapshot {
        let browserContext = browserPageContext(for: app)
        let windowTitle = ClipboardAutomationService.focusedWindowTitle(from: app)
        let selectedText = normalizedSelection(
            preferredSelection ?? ClipboardAutomationService.currentSelectionText(from: app)
        )

        return FocusSnapshot(
            appName: app.localizedName ?? "Unknown App",
            bundleIdentifier: app.bundleIdentifier,
            windowTitle: windowTitle,
            pageTitle: browserContext?.title,
            urlString: browserContext?.urlString,
            selectedText: selectedText,
            capturedAt: Date()
        )
    }

    @discardableResult
    static func resume(_ snapshot: FocusSnapshot) -> Bool {
        if let urlString = snapshot.urlString,
           let url = URL(string: urlString) {
            if let bundleIdentifier = snapshot.bundleIdentifier,
               open(urlString: url.absoluteString, inBundleIdentifier: bundleIdentifier) {
                return true
            }
            return NSWorkspace.shared.open(url)
        }

        if let bundleIdentifier = snapshot.bundleIdentifier,
           let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            return runningApp.activate()
        }

        if let bundleIdentifier = snapshot.bundleIdentifier,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, _ in }
            return true
        }

        return false
    }

    private static func normalizedSelection(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(4_000))
    }

    private static func browserPageContext(for app: NSRunningApplication) -> BrowserPageContext? {
        guard let bundleIdentifier = app.bundleIdentifier else { return nil }

        switch bundleIdentifier {
        case "com.apple.Safari":
            return safariPageContext()
        case "com.google.Chrome",
             "com.brave.Browser",
             "com.microsoft.edgemac",
             "company.thebrowser.Browser":
            return chromiumPageContext(bundleIdentifier: bundleIdentifier)
        default:
            return nil
        }
    }

    private static func safariPageContext() -> BrowserPageContext? {
        let script = [
            "tell application id \"com.apple.Safari\"",
            "if (count of windows) is 0 then return \"\"",
            "set currentTab to current tab of front window",
            "return (name of currentTab as string) & linefeed & (URL of currentTab as string)",
            "end tell"
        ]

        return browserContext(from: script)
    }

    private static func chromiumPageContext(bundleIdentifier: String) -> BrowserPageContext? {
        let script = [
            "tell application id \"\(bundleIdentifier)\"",
            "if (count of windows) is 0 then return \"\"",
            "set activeTab to active tab of front window",
            "return (title of activeTab as string) & linefeed & (URL of activeTab as string)",
            "end tell"
        ]

        return browserContext(from: script)
    }

    private static func browserContext(from scriptLines: [String]) -> BrowserPageContext? {
        guard let raw = runAppleScript(scriptLines),
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let parts = raw.components(separatedBy: .newlines)
        let title = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = parts.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        return BrowserPageContext(
            title: title?.isEmpty == true ? nil : title,
            urlString: urlString.isEmpty ? nil : urlString
        )
    }

    private static func runAppleScript(_ scriptLines: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = scriptLines.flatMap { ["-e", $0] }

        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = standardOutput.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func open(urlString: String, inBundleIdentifier bundleIdentifier: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-b", bundleIdentifier, urlString]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
