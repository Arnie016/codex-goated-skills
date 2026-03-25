import SwiftUI

@main
struct XboxStudioApp: App {
    @StateObject private var model = XboxStudioModel()

    var body: some Scene {
        WindowGroup(id: "dashboard") {
            DashboardView(model: model)
                .frame(minWidth: 980, minHeight: 700)
        }
        .defaultSize(width: 1120, height: 760)
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Label("Xbox Studio", systemImage: model.menuBarSymbolName)
                .help(model.menuBarHelp)
        }
        .menuBarExtraStyle(.window)

        Settings {
            VStack(alignment: .leading, spacing: 12) {
                Text("Xbox Studio")
                    .font(.title2.weight(.bold))
                Text("A grounded macOS helper for Xbox cloud gaming, Remote Play launch, controller readiness, connectivity checks, and capture imports.")
                    .foregroundStyle(.secondary)
                Text("Capture inbox: \(model.captureDirectory.path)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(width: 460)
        }
    }
}
