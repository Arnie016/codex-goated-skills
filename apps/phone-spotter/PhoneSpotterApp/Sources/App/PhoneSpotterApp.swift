import SwiftUI

@main
struct PhoneSpotterApp: App {
    @NSApplicationDelegateAdaptor(PhoneSpotterAppDelegate.self) private var appDelegate
    @StateObject private var model = PhoneSpotterAppModel.shared

    var body: some Scene {
        Settings {
            PhoneSpotterSettingsView(model: model)
                .frame(width: 520, height: 520)
        }
    }
}
