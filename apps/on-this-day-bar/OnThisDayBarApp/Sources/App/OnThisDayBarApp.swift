import SwiftUI

@main
struct OnThisDayBarApp: App {
    @StateObject private var model = OnThisDayBarAppModel()

    var body: some Scene {
        MenuBarExtra {
            OnThisDayBarMenuBarView(model: model)
                .task {
                    await model.refreshIfNeeded()
                }
        } label: {
            Label(model.menuBarTitle, systemImage: model.menuBarSymbolName)
        }
        .menuBarExtraStyle(.window)

        Settings {
            OnThisDayBarSettingsView(model: model)
                .frame(width: 420, height: 320)
        }
    }
}
