import SwiftUI

@main
struct ImpeccableCLIPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Impeccable CLI", systemImage: "paintbrush.pointed.fill") {
            ImpeccableCLIMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
