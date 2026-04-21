import SwiftUI

@main
struct FinderSelectionRelayPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Finder Selection Relay", systemImage: "folder.badge.plus") {
            FinderSelectionRelayMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
