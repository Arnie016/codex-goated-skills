import SwiftUI

@main
struct SVGTo3DForgePrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("SVG To 3D Forge", systemImage: "cube.transparent") {
            SVGTo3DForgeMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
