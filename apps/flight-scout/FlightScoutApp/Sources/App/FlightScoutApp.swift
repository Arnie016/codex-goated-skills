import SwiftUI

@main
struct FlightScoutApp: App {
    @NSApplicationDelegateAdaptor(FlightScoutAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            VStack(alignment: .leading, spacing: 8) {
                Text("Flight Scout")
                    .font(.headline)
                Text("Flight Scout lives in the menu bar and tracks live routes, booking links, and destination risk from your current VPN region.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Use the compact panel for top routes, then open the board for tracked destinations, risk breakdowns, headlines, and exports.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(width: 360)
        }
    }
}
