import SwiftUI

@main
struct ChromeTabSweeperPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Chrome Tab Sweeper", systemImage: "rectangle.stack.badge.minus") {
            ChromeTabSweeperMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
