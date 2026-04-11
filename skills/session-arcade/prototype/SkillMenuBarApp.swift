import SwiftUI

@main
struct SessionArcadePrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Session Arcade", systemImage: "gamecontroller.fill") {
            SessionArcadeMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
