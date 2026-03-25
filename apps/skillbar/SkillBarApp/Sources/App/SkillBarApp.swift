import SwiftUI

@main
struct SkillBarApp: App {
    @StateObject private var model = SkillBarModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            SkillBarMenuIcon(isBusy: model.isBusy, installedCount: model.installedCount)
                .help(model.menuBarHelp)
        }
        .menuBarExtraStyle(.window)
    }
}
