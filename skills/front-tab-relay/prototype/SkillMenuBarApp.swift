import SwiftUI

@main
struct FrontTabRelayPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Front Tab Relay", systemImage: "link.badge.plus") {
            FrontTabRelayMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
