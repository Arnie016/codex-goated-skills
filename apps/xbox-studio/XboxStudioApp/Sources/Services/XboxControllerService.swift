import AppKit
import CoreBluetooth
import Foundation
import GameController

final class XboxControllerService: NSObject, CBCentralManagerDelegate {
    var onChange: ((XboxControllerSnapshot) -> Void)?

    private var centralManager: CBCentralManager!
    private var bluetoothState: CBManagerState = .unknown

    override init() {
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: false]
        )

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(handleControllerChange), name: .GCControllerDidConnect, object: nil)
        center.addObserver(self, selector: #selector(handleControllerChange), name: .GCControllerDidDisconnect, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func currentSnapshot() -> XboxControllerSnapshot {
        makeSnapshot()
    }

    func openBluetoothSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") else { return }
        NSWorkspace.shared.open(url)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        publish()
    }

    @objc
    private func handleControllerChange() {
        publish()
    }

    private func publish() {
        onChange?(makeSnapshot())
    }

    private func settingsAction(primary: Bool) -> XboxControllerAction {
        XboxControllerAction(
            kind: .openBluetoothSettings,
            title: "Open Bluetooth Settings",
            systemImage: "dot.radiowaves.left.and.right",
            isPrimary: primary
        )
    }

    private func pairingGuideAction(primary: Bool, title: String = "Open Apple Pairing Guide") -> XboxControllerAction {
        XboxControllerAction(
            kind: .openApplePairingGuide,
            title: title,
            systemImage: "book.closed",
            isPrimary: primary
        )
    }

    private func xboxGuideAction(primary: Bool, title: String = "Open Xbox Controller Help") -> XboxControllerAction {
        XboxControllerAction(
            kind: .openXboxControllerGuide,
            title: title,
            systemImage: "questionmark.circle",
            isPrimary: primary
        )
    }

    private func refreshAction(primary: Bool) -> XboxControllerAction {
        XboxControllerAction(
            kind: .refreshChecks,
            title: "Refresh Checks",
            systemImage: "arrow.clockwise",
            isPrimary: primary
        )
    }

    private func makeSnapshot() -> XboxControllerSnapshot {
        let bluetoothTitle: String
        let bluetoothDetail: String
        let bluetoothLevel: XboxStatusLevel

        switch bluetoothState {
        case .poweredOn:
            bluetoothTitle = "Bluetooth is ready"
            bluetoothDetail = "Pair supported Xbox controllers from macOS Bluetooth settings."
            bluetoothLevel = .good
        case .poweredOff:
            bluetoothTitle = "Bluetooth is off"
            bluetoothDetail = "Turn Bluetooth on before pairing or testing controllers."
            bluetoothLevel = .warning
        case .unauthorized:
            bluetoothTitle = "Bluetooth permission needed"
            bluetoothDetail = "Allow Bluetooth access if you want readiness checks inside the app."
            bluetoothLevel = .warning
        case .unsupported:
            bluetoothTitle = "Bluetooth unsupported"
            bluetoothDetail = "This Mac cannot expose Bluetooth readiness to the app."
            bluetoothLevel = .critical
        case .resetting:
            bluetoothTitle = "Bluetooth is resetting"
            bluetoothDetail = "Wait a moment and refresh controller status."
            bluetoothLevel = .warning
        case .unknown:
            fallthrough
        @unknown default:
            bluetoothTitle = "Checking Bluetooth"
            bluetoothDetail = "Reading local controller readiness."
            bluetoothLevel = .neutral
        }

        let controllers = GCController.controllers().map { controller -> XboxControllerRow in
            let vendor = controller.vendorName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = vendor?.isEmpty == false ? vendor! : "Game Controller"
            let category = controller.productCategory.isEmpty ? "Generic profile" : controller.productCategory
            let profile: String
            if controller.extendedGamepad != nil {
                profile = "Extended gamepad"
            } else if controller.microGamepad != nil {
                profile = "Micro gamepad"
            } else {
                profile = "Physical input"
            }

            let looksLikeXbox = name.localizedCaseInsensitiveContains("xbox")
                || category.localizedCaseInsensitiveContains("xbox")
            let detail = "\(profile) • \(category)"

            return XboxControllerRow(
                name: name,
                detail: detail,
                isXboxFamily: looksLikeXbox,
                isCurrent: controller == GCController.current
            )
        }

        let summaryTitle: String
        let summaryDetail: String
        let primaryCard: XboxControllerStatusCard

        switch bluetoothState {
        case .poweredOff:
            summaryTitle = "Bluetooth is off"
            summaryDetail = "Turn Bluetooth on before pairing or checking an Xbox controller."
            primaryCard = XboxControllerStatusCard(
                id: "bluetooth-off",
                title: "Bluetooth is off",
                detail: "Xbox Studio cannot detect controllers until Bluetooth is on. Open Bluetooth settings first, then pair your controller in the Apple-managed flow.",
                level: .warning,
                symbolName: "antenna.radiowaves.left.and.right.slash",
                badge: "Bluetooth",
                actions: [
                    settingsAction(primary: true),
                    pairingGuideAction(primary: false),
                    refreshAction(primary: false),
                ]
            )
        case .unauthorized:
            summaryTitle = "Bluetooth permission needed"
            summaryDetail = "Allow Bluetooth access if you want controller readiness checks in the app."
            primaryCard = XboxControllerStatusCard(
                id: "bluetooth-permission",
                title: "Bluetooth permission needed",
                detail: "macOS has not granted Bluetooth access to Xbox Studio yet. Use the Apple settings flow, then refresh the controller check.",
                level: .warning,
                symbolName: "hand.raised.circle.fill",
                badge: "Permission",
                actions: [
                    settingsAction(primary: true),
                    pairingGuideAction(primary: false),
                    refreshAction(primary: false),
                ]
            )
        case .unsupported:
            summaryTitle = "Bluetooth unsupported"
            summaryDetail = "This Mac cannot expose Bluetooth readiness to Xbox Studio."
            primaryCard = XboxControllerStatusCard(
                id: "bluetooth-unsupported",
                title: "Bluetooth unsupported",
                detail: "Xbox Studio cannot read Bluetooth readiness on this Mac, so controller pairing has to stay in Apple-managed settings and support surfaces.",
                level: .critical,
                symbolName: "xmark.octagon.fill",
                badge: "Unsupported",
                actions: [
                    pairingGuideAction(primary: true),
                    xboxGuideAction(primary: false),
                    refreshAction(primary: false),
                ]
            )
        case .resetting, .unknown:
            summaryTitle = "Checking Bluetooth"
            summaryDetail = "The local Bluetooth stack is still settling or unreadable."
            primaryCard = XboxControllerStatusCard(
                id: "bluetooth-checking",
                title: "Checking Bluetooth",
                detail: "Xbox Studio is waiting for the local Bluetooth stack to settle. Refresh the checks in a moment if controller status does not appear.",
                level: .neutral,
                symbolName: "bolt.horizontal.circle.fill",
                badge: "Checking",
                actions: [
                    refreshAction(primary: true),
                    pairingGuideAction(primary: false),
                    xboxGuideAction(primary: false),
                ]
            )
        case .poweredOn:
            if controllers.isEmpty {
                summaryTitle = "No controller detected"
                summaryDetail = "Bluetooth is ready, but GameController does not see an active controller yet."
                primaryCard = XboxControllerStatusCard(
                    id: "no-controller",
                    title: "No controller detected",
                    detail: "Bluetooth is ready. Pair a supported Xbox controller in macOS Bluetooth settings, then come back here to confirm the connection.",
                    level: .warning,
                    symbolName: "gamecontroller",
                    badge: "Pairing",
                    actions: [
                        settingsAction(primary: true),
                        pairingGuideAction(primary: false),
                        xboxGuideAction(primary: false),
                    ]
                )
            } else if !controllers.contains(where: \.isXboxFamily) {
                summaryTitle = "Non-Xbox controller detected"
                summaryDetail = "A controller is connected, but it does not look like Xbox-family hardware."
                primaryCard = XboxControllerStatusCard(
                    id: "non-xbox-controller",
                    title: "A controller is connected, but it does not look like Xbox hardware",
                    detail: "Xbox Studio sees a game controller through Apple's frameworks, but it does not currently look like an Xbox-family pad. Re-check the paired device if you expected Xbox hardware.",
                    level: .warning,
                    symbolName: "gamecontroller",
                    badge: "Detected",
                    actions: [
                        pairingGuideAction(primary: true),
                        settingsAction(primary: false),
                        xboxGuideAction(primary: false),
                    ]
                )
            } else {
                summaryTitle = "Xbox controller connected"
                summaryDetail = "An Xbox-family controller is visible to the Mac and ready for the next step."
                primaryCard = XboxControllerStatusCard(
                    id: "xbox-controller-connected",
                    title: "Xbox controller connected",
                    detail: "Xbox Studio can see Xbox-family hardware through Apple's GameController framework. You are ready to jump into Cloud Gaming, Remote Play, or a quick firmware check.",
                    level: .good,
                    symbolName: "checkmark.circle.fill",
                    badge: "Ready",
                    actions: [
                        refreshAction(primary: true),
                        xboxGuideAction(primary: false, title: "Open Firmware Guide"),
                        settingsAction(primary: false),
                    ]
                )
            }
        @unknown default:
            summaryTitle = "Checking Bluetooth"
            summaryDetail = "Xbox Studio is reading local controller readiness."
            primaryCard = XboxControllerStatusCard(
                id: "bluetooth-checking",
                title: "Checking Bluetooth",
                detail: "Xbox Studio is reading local controller readiness on this Mac.",
                level: .neutral,
                symbolName: "bolt.horizontal.circle.fill",
                badge: "Checking",
                actions: [
                    refreshAction(primary: true),
                    pairingGuideAction(primary: false),
                    xboxGuideAction(primary: false),
                ]
            )
        }

        return XboxControllerSnapshot(
            bluetoothTitle: bluetoothTitle,
            bluetoothDetail: bluetoothDetail,
            bluetoothLevel: bluetoothLevel,
            summaryTitle: summaryTitle,
            summaryDetail: summaryDetail,
            primaryCard: primaryCard,
            controllers: controllers
        )
    }
}
