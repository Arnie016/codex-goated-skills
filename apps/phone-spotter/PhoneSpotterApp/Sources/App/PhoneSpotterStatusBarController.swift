import AppKit
import Combine
import SwiftUI

@MainActor
final class PhoneSpotterAppDelegate: NSObject, NSApplicationDelegate {
    private let model = PhoneSpotterAppModel.shared
    private var statusBarController: PhoneSpotterStatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = PhoneSpotterStatusBarController(model: model)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.statusBarController?.showPanel()
        }
    }
}

@MainActor
final class PhoneSpotterStatusBarController: NSObject {
    private let model: PhoneSpotterAppModel
    private let statusItem: NSStatusItem
    private let panelController: PhoneSpotterPanelController
    private var cancellables: Set<AnyCancellable> = []

    init(model: PhoneSpotterAppModel) {
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.panelController = PhoneSpotterPanelController(model: model)
        super.init()

        configureStatusItem()
        bindModel()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleStatusItemPress(_:))
        button.sendAction(on: [.leftMouseDown, .rightMouseUp])
        button.imagePosition = .imageOnly
        button.setAccessibilityTitle("Phone Spotter")
        updateStatusItemAppearance()
    }

    private func bindModel() {
        Publishers.CombineLatest4(model.$platform, model.$providerStatus, model.$feedbackMessage, model.$errorMessage)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _, _ in
                self?.updateStatusItemAppearance()
            }
            .store(in: &cancellables)
    }

    private func updateStatusItemAppearance() {
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: model.menuBarSymbolName, accessibilityDescription: "Phone Spotter")
        image?.isTemplate = true
        button.image = image
        button.toolTip = model.errorMessage ?? model.feedbackMessage ?? model.panelSubtitle
    }

    @objc
    private func handleStatusItemPress(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            panelController.show(relativeTo: statusItem.button)
            return
        }

        if event.type == .rightMouseUp {
            statusItem.menu = makeMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            panelController.show(relativeTo: statusItem.button)
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Phone Spotter", action: #selector(openPanelFromMenu), keyEquivalent: "")
        menu.addItem(withTitle: "Pair Phone", action: #selector(startPairingFromMenu), keyEquivalent: "p")
        menu.addItem(withTitle: "Open Pairing Page", action: #selector(openPairingPageFromMenu), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Locate Phone", action: #selector(locatePhone), keyEquivalent: "l")
        menu.addItem(withTitle: "Ring Phone", action: #selector(ringPhone), keyEquivalent: "r")
        menu.addItem(withTitle: "Call Phone", action: #selector(callPhone), keyEquivalent: "c")
        menu.addItem(withTitle: "Open Provider", action: #selector(openProvider), keyEquivalent: "o")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(withTitle: "Quit Phone Spotter", action: #selector(quitApp), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        return menu
    }

    @objc private func openPanelFromMenu() { schedulePanelPresentation() }
    @objc private func startPairingFromMenu() {
        model.startPairingSession()
        schedulePanelPresentation()
    }
    @objc private func openPairingPageFromMenu() {
        if !model.isPairingActive {
            model.startPairingSession()
        }
        schedulePanelPresentation()
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            self?.model.openPairingLink()
        }
    }
    @objc private func locatePhone() { model.locatePhone() }
    @objc private func ringPhone() { model.ringPhone() }
    @objc private func callPhone() { model.callPhone() }
    @objc private func openProvider() { model.openProviderPortal() }
    @objc private func openSettings() { model.openSettings() }
    @objc private func quitApp() { model.quitApp() }

    func showPanel() {
        panelController.show(relativeTo: statusItem.button)
    }

    private func schedulePanelPresentation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
            self?.panelController.show(relativeTo: self?.statusItem.button)
        }
    }
}

private final class PhoneSpotterUtilityPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class PhoneSpotterPanelController: NSObject, NSWindowDelegate {
    private let model: PhoneSpotterAppModel
    private lazy var hostingController = NSHostingController(rootView: PhoneSpotterMenuBarView(model: model))

    private lazy var panel: PhoneSpotterUtilityPanel = {
        let panel = PhoneSpotterUtilityPanel(
            contentRect: NSRect(x: 0, y: 0, width: 392, height: 626),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.title = "Phone Spotter"
        panel.titleVisibility = .visible
        panel.titlebarAppearsTransparent = false
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isFloatingPanel = false
        panel.level = .normal
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .windowBackgroundColor
        panel.isOpaque = false
        panel.hasShadow = true
        panel.delegate = self
        panel.setFrameAutosaveName("PhoneSpotterPanel")
        return panel
    }()

    init(model: PhoneSpotterAppModel) {
        self.model = model
    }

    func show(relativeTo button: NSStatusBarButton?) {
        hostingController.rootView = PhoneSpotterMenuBarView(model: model)
        positionPanel(relativeTo: button)
        NSApp.activate(ignoringOtherApps: true)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    private func positionPanel(relativeTo button: NSStatusBarButton?) {
        guard let button, let buttonWindow = button.window else {
            panel.center()
            return
        }

        let buttonFrameOnScreen = buttonWindow.convertToScreen(button.frame)
        let visibleFrame = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let panelSize = panel.frame.size

        let originX = min(
            max(buttonFrameOnScreen.maxX - panelSize.width, visibleFrame.minX + 8),
            visibleFrame.maxX - panelSize.width - 8
        )
        let originY = max(visibleFrame.minY + 8, buttonFrameOnScreen.minY - panelSize.height - 8)
        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
    }
}
