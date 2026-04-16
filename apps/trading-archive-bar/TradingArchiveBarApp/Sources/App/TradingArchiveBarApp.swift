import SwiftUI

@main
struct TradingArchiveBarApp: App {
    @StateObject private var model = TradingArchiveBarAppModel()

    var body: some Scene {
        MenuBarExtra {
            TradingArchiveBarMenuBarView(model: model)
                .task {
                    await model.refreshIfNeeded()
                }
        } label: {
            Label(model.menuBarTitle, systemImage: model.menuBarSymbolName)
        }
        .menuBarExtraStyle(.window)

        Settings {
            TradingArchiveBarSettingsView(model: model)
                .frame(width: 420, height: 320)
        }
    }
}
