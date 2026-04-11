import SwiftUI

@main
struct StoryArcBoardPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Story Arc Board", systemImage: "bubble.left.and.bubble.right.fill") {
            StoryArcBoardMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
