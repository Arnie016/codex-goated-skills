import SwiftUI

@main
struct HandoffCourierPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Handoff Courier", systemImage: "tray.and.arrow.down.fill") {
            HandoffCourierMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
