import SwiftUI

@main
struct MeetingLinkBridgePrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Meeting Link Bridge", systemImage: "video.badge.plus") {
            MeetingLinkBridgeMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
