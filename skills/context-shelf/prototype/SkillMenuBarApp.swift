import SwiftUI

@main
struct ContextShelfPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Context Shelf", systemImage: "square.stack.3d.up.fill") {
            ContextShelfMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
