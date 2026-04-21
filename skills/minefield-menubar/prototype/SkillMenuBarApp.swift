import SwiftUI

@main
struct MinefieldMenuBarPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Minefield", systemImage: "diamond.fill") {
            MinefieldMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
