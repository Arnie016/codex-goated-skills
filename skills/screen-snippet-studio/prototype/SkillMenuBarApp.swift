import SwiftUI

@main
struct ScreenSnippetStudioPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Screen Snippet Studio", systemImage: "viewfinder") {
            ScreenSnippetStudioMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
