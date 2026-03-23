import SwiftUI

@main
struct TeleBarApp: App {
    @StateObject private var model = TeleBarModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Image(systemName: model.menuBarSymbolName)
                .font(.system(size: 14, weight: .semibold))
                .help(model.menuBarHelp)
        }
        .menuBarExtraStyle(.window)
    }
}
