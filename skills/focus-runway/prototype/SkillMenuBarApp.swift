import SwiftUI

@main
struct FocusRunwayPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Focus Runway", systemImage: "arrow.clockwise") {
            FocusRunwayMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
