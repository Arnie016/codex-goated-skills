import SwiftUI

@main
struct SecuritySentryBarApp: App {
    var body: some Scene {
        MenuBarExtra {
            SecuritySentryBarMenuBarView()
        } label: {
            Label("Security Sentry", systemImage: "checkmark.shield.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
