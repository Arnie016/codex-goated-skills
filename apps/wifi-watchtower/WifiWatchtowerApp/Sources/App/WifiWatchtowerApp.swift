import SwiftUI

@main
struct WifiWatchtowerApp: App {
    @StateObject private var model = WatchtowerModel()

    var body: some Scene {
        WindowGroup(id: "dashboard") {
            DashboardView(model: model)
                .frame(minWidth: 920, minHeight: 620)
        }
        .defaultSize(width: 1040, height: 700)
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Label("WiFi Watchtower", systemImage: model.menuBarSymbolName)
                .help(model.snapshot.headline)
        }
        .menuBarExtraStyle(.window)
    }
}
