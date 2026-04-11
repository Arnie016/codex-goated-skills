import SwiftUI

@main
struct LaunchDeckLiftPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Launch Deck Lift", systemImage: "rectangle.3.group.fill") {
            LaunchDeckLiftMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
