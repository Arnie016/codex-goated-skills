import SwiftUI

@main
struct MinesweeperMenuBarPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Minesweeper", systemImage: "flag.pattern.checkered") {
            MinesweeperMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
