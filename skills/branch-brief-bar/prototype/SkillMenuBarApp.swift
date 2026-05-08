import SwiftUI

@main
struct BranchBriefBarPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Branch Brief Bar", systemImage: "square.and.arrow.up.fill") {
            BranchBriefBarMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
