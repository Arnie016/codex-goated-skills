import SwiftUI

@main
struct PowerSentryPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Power Sentry", systemImage: "battery.100") {
            PowerSentryMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
