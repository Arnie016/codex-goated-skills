import SwiftUI

@main
struct ReaderModeBridgePrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Reader Mode Bridge", systemImage: "doc.text.magnifyingglass") {
            ReaderModeBridgeMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
