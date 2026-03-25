import AppKit
import Combine
import SwiftUI

@MainActor
final class FlightScoutAppDelegate: NSObject, NSApplicationDelegate {
    private let model = FlightScoutAppModel()
    private var statusBarController: FlightScoutStatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = FlightScoutStatusBarController(model: model)
    }
}

@MainActor
final class FlightScoutStatusBarController: NSObject {
    private let model: FlightScoutAppModel
    private let statusItem: NSStatusItem
    private let panelController: FlightScoutPanelController
    private let boardController: FlightScoutBoardController
    private var cancellables: Set<AnyCancellable> = []

    init(model: FlightScoutAppModel) {
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.panelController = FlightScoutPanelController(model: model)
        self.boardController = FlightScoutBoardController(model: model)
        super.init()
        configureStatusItem()
        bindModel()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleStatusItemPress(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageOnly
        button.setAccessibilityTitle("Flight Scout")
        updateStatusItemAppearance()
    }

    private func bindModel() {
        Publishers.CombineLatest3(model.$isLoading, model.$errorMessage, model.$snapshot)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.updateStatusItemAppearance()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .flightScoutOpenBoard)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.boardController.show()
            }
            .store(in: &cancellables)
    }

    private func updateStatusItemAppearance() {
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: model.menuBarSymbolName, accessibilityDescription: "Flight Scout")
        image?.isTemplate = true
        button.image = image
        button.title = ""
        button.toolTip = model.panelSubtitle
    }

    @objc
    private func handleStatusItemPress(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            panelController.toggle(relativeTo: statusItem.button)
            return
        }

        if event.type == .rightMouseUp {
            statusItem.menu = makeMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            panelController.toggle(relativeTo: statusItem.button)
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Flight Scout", action: #selector(openPanelFromMenu), keyEquivalent: "")
        menu.addItem(withTitle: "Open Board", action: #selector(openBoardFromMenu), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Flight Scout", action: #selector(quitApp), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        return menu
    }

    @objc
    private func openPanelFromMenu() {
        panelController.toggle(relativeTo: statusItem.button)
    }

    @objc
    private func openBoardFromMenu() {
        boardController.show()
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let flightScoutOpenBoard = Notification.Name("FlightScoutOpenBoard")
}

private final class FlightScoutUtilityPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class FlightScoutBoardController: NSObject {
    private let model: FlightScoutAppModel
    private lazy var hostingController: NSHostingController<FlightScoutBoardView> = {
        let controller = NSHostingController(rootView: FlightScoutBoardView(model: model))
        controller.sizingOptions = [.preferredContentSize]
        return controller
    }()

    private lazy var window: NSWindow = {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1080, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Flight Scout Board"
        window.titleVisibility = .visible
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("FlightScoutBoard")
        window.center()
        return window
    }()

    init(model: FlightScoutAppModel) {
        self.model = model
    }

    func show() {
        hostingController.rootView = FlightScoutBoardView(model: model)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
final class FlightScoutPanelController: NSObject {
    private let model: FlightScoutAppModel
    private lazy var hostingController = NSHostingController(rootView: FlightScoutMenuBarView(model: model))

    private lazy var panel: FlightScoutUtilityPanel = {
        let panel = FlightScoutUtilityPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 424),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        return panel
    }()

    init(model: FlightScoutAppModel) {
        self.model = model
    }

    func toggle(relativeTo button: NSStatusBarButton?) {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            show(relativeTo: button)
        }
    }

    func show(relativeTo button: NSStatusBarButton?) {
        hostingController.rootView = FlightScoutMenuBarView(model: model)
        positionPanel(relativeTo: button)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
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
        let originY = buttonFrameOnScreen.minY - panelSize.height - 8

        panel.setFrameOrigin(NSPoint(x: originX, y: max(visibleFrame.minY + 8, originY)))
    }
}
