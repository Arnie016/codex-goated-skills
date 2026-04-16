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
        VStack(alignment: .leading, spacing: 18) {
            Text(ContextAssemblyBrand.appName)
                .font(.title2.weight(.bold))
            Text("Capture code, logs, pages, and notes from Xcode, Cursor, VS Code, Terminal, browsers, or documents, then paste or export one structured assembly without losing your place.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                Text("Default hot actions")
                    .font(.headline)
                Text("\(ClipboardStudioShortcut.captureSelection.keyChord) Capture the current selection and start the assembly timeline if it is empty.")
                Text("\(ClipboardStudioShortcut.sendPack.keyChord) Paste the active assembly into the app you were just using.")
                Text("\(ClipboardStudioShortcut.openPack.keyChord) Open or close the floating assembly window.")
                Text("Current Focus keeps the latest page, window, or selection at the top and remembers it across relaunches.")
                Text("Recent States let you reopen a saved browser page or bring an app back to the front later.")
                Text("Export sends the current assembly to Apple Notes or saves Markdown straight into a remembered folder.")
                Text("Direct send uses Accessibility. Browser page details may also ask macOS for Automation access.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("OpenAI Research")
                    .font(.headline)

                Text("Save an API key to let Context Assembly turn the current page or selection into a compact research brief and add it to the assembly.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                SecureField("OpenAI API Key", text: $model.openAIKeyInput)

                HStack(spacing: 10) {
                    Button(model.hasStoredOpenAIKey ? "Update Key" : "Save Key") {
                        model.saveOpenAIKey()
                    }
                    .buttonStyle(.borderedProminent)

                    if model.hasStoredOpenAIKey {
                        Button("Remove Stored Key") {
                            model.clearStoredOpenAIKey()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 500)
    }
}
