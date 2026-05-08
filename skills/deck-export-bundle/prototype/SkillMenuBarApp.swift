import SwiftUI

@main
struct DeckExportBundlePrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Deck Export Bundle", systemImage: "square.and.arrow.up") {
            DeckExportBundleMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
