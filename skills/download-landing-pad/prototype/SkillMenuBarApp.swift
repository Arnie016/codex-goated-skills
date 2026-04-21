import SwiftUI

@main
struct DownloadLandingPadPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Download Landing Pad", systemImage: "tray.and.arrow.down.fill") {
            DownloadLandingPadMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
