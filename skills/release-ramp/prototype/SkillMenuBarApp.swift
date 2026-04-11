import SwiftUI

@main
struct ReleaseRampPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Release Ramp", systemImage: "shippingbox.fill") {
            ReleaseRampMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
