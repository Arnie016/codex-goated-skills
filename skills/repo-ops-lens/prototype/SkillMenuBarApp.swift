import SwiftUI

@main
struct RepoOpsLensPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Repo Ops Lens", systemImage: "magnifyingglass.circle.fill") {
            RepoOpsLensMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
