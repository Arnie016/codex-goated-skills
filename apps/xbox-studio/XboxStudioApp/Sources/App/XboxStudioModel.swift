import AppKit
import Combine
import SwiftUI

enum XboxStatusLevel: String {
    case good
    case warning
    case critical
    case neutral

    var color: Color {
        switch self {
        case .good:
            return Color(red: 0.22, green: 0.74, blue: 0.42)
        case .warning:
            return Color(red: 0.98, green: 0.67, blue: 0.19)
        case .critical:
            return Color(red: 0.93, green: 0.33, blue: 0.31)
        case .neutral:
            return Color(red: 0.45, green: 0.71, blue: 0.98)
        }
    }

    var symbolName: String {
        switch self {
        case .good:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
        case .neutral:
            return "bolt.horizontal.circle.fill"
        }
    }
}

struct XboxEndpointProbe: Identifiable {
    let id = UUID()
    let name: String
    let destination: String
    let status: XboxStatusLevel
    let summary: String
    let detail: String
}

struct XboxConnectivitySnapshot {
    var headline: String
    var detail: String
    var level: XboxStatusLevel
    var probes: [XboxEndpointProbe]
    var checkedAtLabel: String

    static let placeholder = XboxConnectivitySnapshot(
        headline: "Checking Xbox surfaces",
        detail: "Running browser reachability checks and reading local path status.",
        level: .neutral,
        probes: [
            XboxEndpointProbe(
                name: "Cloud Gaming",
                destination: "xbox.com/play",
                status: .neutral,
                summary: "Waiting",
                detail: "No probe yet"
            )
        ],
        checkedAtLabel: "Waiting"
    )
}

struct XboxControllerRow: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let isXboxFamily: Bool
    let isCurrent: Bool
}

enum XboxControllerActionKind: String {
    case openBluetoothSettings
    case openApplePairingGuide
    case openXboxControllerGuide
    case refreshChecks
}

struct XboxControllerAction: Identifiable {
    let kind: XboxControllerActionKind
    let title: String
    let systemImage: String
    let isPrimary: Bool

    var id: String {
        "\(kind.rawValue)-\(title)"
    }
}

struct XboxControllerStatusCard: Identifiable {
    let id: String
    let title: String
    let detail: String
    let level: XboxStatusLevel
    let symbolName: String
    let badge: String?
    let actions: [XboxControllerAction]
}

struct XboxControllerSnapshot {
    var bluetoothTitle: String
    var bluetoothDetail: String
    var bluetoothLevel: XboxStatusLevel
    var summaryTitle: String
    var summaryDetail: String
    var primaryCard: XboxControllerStatusCard
    var controllers: [XboxControllerRow]

    var controllerCount: Int {
        controllers.count
    }

    var xboxControllerCount: Int {
        controllers.filter(\.isXboxFamily).count
    }

    var hasXboxController: Bool {
        xboxControllerCount > 0
    }

    static let placeholder = XboxControllerSnapshot(
        bluetoothTitle: "Checking Bluetooth",
        bluetoothDetail: "Looking for controller readiness on this Mac.",
        bluetoothLevel: .neutral,
        summaryTitle: "Controller readiness is loading",
        summaryDetail: "Xbox Studio is reading Bluetooth and controller state.",
        primaryCard: XboxControllerStatusCard(
            id: "checking",
            title: "Checking Bluetooth",
            detail: "Xbox Studio is reading local controller readiness on this Mac.",
            level: .neutral,
            symbolName: "bolt.horizontal.circle.fill",
            badge: "Checking",
            actions: [
                XboxControllerAction(
                    kind: .refreshChecks,
                    title: "Refresh Checks",
                    systemImage: "arrow.clockwise",
                    isPrimary: true
                )
            ]
        ),
        controllers: []
    )
}

struct CaptureAsset: Identifiable {
    let id: String
    let fileURL: URL
    let title: String
    let subtitle: String
    let badge: String
    let modifiedAt: Date
}

@MainActor
final class XboxStudioModel: ObservableObject {
    @Published var connectivity = XboxConnectivitySnapshot.placeholder
    @Published var controllers = XboxControllerSnapshot.placeholder
    @Published var captures: [CaptureAsset] = []
    @Published var isRefreshing = false
    @Published var lastError: String?
    @Published var lastImportMessage: String?
    @Published var playerLabel: String {
        didSet {
            UserDefaults.standard.set(playerLabel, forKey: Self.playerLabelDefaultsKey)
        }
    }

    private static let playerLabelDefaultsKey = "XboxStudioPlayerLabel"

    private let connectivityService = XboxConnectivityService()
    private let controllerService = XboxControllerService()
    private let captureService = CaptureInboxService()
    private var timer: Timer?

    init() {
        playerLabel = UserDefaults.standard.string(forKey: Self.playerLabelDefaultsKey) ?? ""

        controllerService.onChange = { [weak self] snapshot in
            guard let self else { return }
            self.controllers = snapshot
        }

        captures = captureService.loadAssets()
        controllers = controllerService.currentSnapshot()
        refresh()

        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    var captureDirectory: URL {
        captureService.captureDirectory
    }

    var menuBarSymbolName: String {
        if controllers.hasXboxController {
            return "gamecontroller.fill"
        }
        if controllers.bluetoothLevel == .warning || controllers.bluetoothLevel == .critical {
            return "antenna.radiowaves.left.and.right.slash"
        }
        if connectivity.level == .critical {
            return "wifi.slash"
        }
        return "gamecontroller"
    }

    var menuBarHelp: String {
        let player = playerLabel.isEmpty ? "Xbox Studio" : playerLabel
        return "\(player) • \(controllers.summaryTitle) • \(controllers.controllerCount) controller(s) • \(captures.count) capture(s)"
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        lastError = nil
        lastImportMessage = nil

        controllers = controllerService.currentSnapshot()
        captures = captureService.loadAssets()

        Task {
            let snapshot = await connectivityService.captureSnapshot()
            connectivity = snapshot
            isRefreshing = false
        }
    }

    func openCloudGaming() {
        openExternalURL(XboxLinks.cloudGaming)
    }

    func openRemotePlay() {
        openExternalURL(XboxLinks.remotePlay)
    }

    func openAccount() {
        openExternalURL(XboxLinks.account)
    }

    func openSupport() {
        openExternalURL(XboxLinks.support)
    }

    func openBluetoothSettings() {
        controllerService.openBluetoothSettings()
    }

    func openApplePairingGuide() {
        openExternalURL(XboxLinks.applePairingGuide)
    }

    func openXboxControllerGuide() {
        openExternalURL(XboxLinks.controllerGuide)
    }

    func openCaptureFolder() {
        captureService.openCaptureFolder()
    }

    func revealCapture(_ asset: CaptureAsset) {
        captureService.reveal(asset)
    }

    func importCaptureFiles(from urls: [URL]) {
        do {
            let result = try captureService.importFiles(from: urls)
            captures = captureService.loadAssets()
            lastImportMessage = result
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(#selector(NSWindowController.showWindow(_:)), to: nil, from: nil)
    }

    func performControllerAction(_ action: XboxControllerAction) {
        switch action.kind {
        case .openBluetoothSettings:
            openBluetoothSettings()
        case .openApplePairingGuide:
            openApplePairingGuide()
        case .openXboxControllerGuide:
            openXboxControllerGuide()
        case .refreshChecks:
            refresh()
        }
    }

    private func openExternalURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
