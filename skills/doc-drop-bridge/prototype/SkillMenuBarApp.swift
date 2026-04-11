import SwiftUI

@main
struct DocDropBridgePrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Doc Drop Bridge", systemImage: "doc.fill") {
            DocDropBridgeMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
