import SwiftUI

@main
struct ExcelRangeRelayPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Excel Range Relay", systemImage: "tablecells") {
            ExcelRangeRelayMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
