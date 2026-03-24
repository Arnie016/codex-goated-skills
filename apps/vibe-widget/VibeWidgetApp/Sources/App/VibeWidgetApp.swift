import AppKit
import SwiftUI

final class VibeWidgetAppDelegate: NSObject, NSApplicationDelegate {
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
struct VibeWidgetApp: App {
    @NSApplicationDelegateAdaptor(VibeWidgetAppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                MentalDeclutterMenuBarIcon(isActive: model.isMindDeclutterActive(at: context.date))
                    .help(model.menuBarHelpText(at: context.date))
            }
        }
        .menuBarExtraStyle(.window)
    }
}
