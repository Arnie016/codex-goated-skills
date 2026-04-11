import SwiftUI

@main
struct PhoneHandoffPanelPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Phone Handoff Panel", systemImage: "iphone") {
            PhoneHandoffPanelMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
