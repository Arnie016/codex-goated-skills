import SwiftUI

@main
struct ReplayRelayPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Replay Relay", systemImage: "film.stack.fill") {
            ReplayRelayMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
