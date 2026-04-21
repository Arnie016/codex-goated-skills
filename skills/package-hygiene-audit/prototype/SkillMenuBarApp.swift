import SwiftUI

@main
struct PackageHygieneAuditPrototypeApp: App {
    var body: some Scene {
        MenuBarExtra("Package Hygiene Audit", systemImage: "checklist.checked") {
            PackageHygieneAuditMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
