import AppKit
import Combine
import SwiftUI

@MainActor
final class WatchtowerModel: ObservableObject {
    @Published var snapshot = NetworkSnapshot.placeholder
    @Published var isRefreshing = false
    @Published var lastError: String?

    private let inspector = WifiInspector()
    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    var menuBarSymbolName: String {
        switch snapshot.trustLevel {
        case .safe:
            return "checkmark.shield.fill"
        case .caution:
            return "exclamationmark.shield.fill"
        case .avoid:
            return "xmark.shield.fill"
        }
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true

        Task {
            do {
                snapshot = try await inspector.captureSnapshot()
                lastError = nil
            } catch {
                lastError = error.localizedDescription
            }
            isRefreshing = false
        }
    }

    func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(#selector(NSWindowController.showWindow(_:)), to: nil, from: nil)
    }
}
