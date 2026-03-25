import AppKit
import SwiftUI

final class ClipboardStudioAppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }

        let currentPID = ProcessInfo.processInfo.processIdentifier
        let runningInstances = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .sorted { $0.processIdentifier < $1.processIdentifier }

        guard let primaryInstance = runningInstances.first,
              primaryInstance.processIdentifier != currentPID else {
            return
        }

        primaryInstance.activate()
        NSApp.terminate(nil)
    }
}

@main
struct ClipboardStudioApp: App {
    @NSApplicationDelegateAdaptor(ClipboardStudioAppDelegate.self) private var appDelegate
    @StateObject private var model = ClipboardStudioModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            ClipboardStudioMenuBarIcon(
                isActive: model.hasPack,
                isAlerting: model.lastSendResult?.delivery == .clipboardFallback
            )
                .help(model.menuBarHelpText)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var model: ClipboardStudioModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Clipboard Studio")
                .font(.title2.weight(.bold))
            Text("Build AI-ready context packs without leaving your flow. Capture from Xcode, Cursor, VS Code, Terminal, or the browser, then send the whole prompt pack straight back into the app you were using.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                Text("Default hot actions")
                    .font(.headline)
                Text("\(ClipboardStudioShortcut.captureSelection.keyChord) Capture the current selection into the prompt pack.")
                Text("\(ClipboardStudioShortcut.sendPack.keyChord) Send the active pack to the last app you were working in.")
                Text("\(ClipboardStudioShortcut.openPack.keyChord) Open the floating pack editor.")
                Text("Direct send uses Accessibility. If macOS blocks automation, Clipboard Studio falls back to copying the pack to your clipboard.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 460)
    }
}
