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

        return XboxControllerSnapshot(
            bluetoothTitle: bluetoothTitle,
            bluetoothDetail: bluetoothDetail,
            bluetoothLevel: bluetoothLevel,
            controllers: controllers
        )
    }
}
