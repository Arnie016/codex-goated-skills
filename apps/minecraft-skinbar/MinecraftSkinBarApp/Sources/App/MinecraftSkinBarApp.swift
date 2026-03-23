import SwiftUI

@main
struct MinecraftSkinBarApp: App {
    @StateObject private var model = SkinBarModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Label("Minecraft Skin Bar", systemImage: model.menuBarSymbolName)
                .help(model.menuBarHelp)
        }
        .menuBarExtraStyle(.window)

        Settings {
            VStack(alignment: .leading, spacing: 12) {
                Text("Minecraft Skin Bar")
                    .font(.title2.weight(.bold))
                Text("Generate or import Minecraft skins from the menu bar, then push them into the local Java launcher skin library.")
                    .foregroundStyle(.secondary)
                Text("Output folder: \(model.outputDirectory.path)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(width: 420)
        }
    }
}
