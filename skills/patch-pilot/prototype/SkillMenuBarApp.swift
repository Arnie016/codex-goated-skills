import SwiftUI

@main
struct PatchPilotPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Patch Pilot", systemImage: "arrow.triangle.branch") {
            PatchPilotMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
