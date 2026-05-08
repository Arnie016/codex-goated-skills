import SwiftUI

@main
struct ReplyQueueBarPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Reply Queue Bar", systemImage: "ellipsis.bubble.fill") {
            ReplyQueueBarMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
