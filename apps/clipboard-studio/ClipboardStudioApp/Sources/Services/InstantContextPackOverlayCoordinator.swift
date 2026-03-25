import AppKit
import SwiftUI

private final class ClipboardOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class InstantContextPackOverlayCoordinator: NSObject, NSWindowDelegate {
    private unowned let model: ClipboardStudioModel
    private var toastDismissWorkItem: DispatchWorkItem?

    private lazy var toastHostingController = NSHostingController(rootView: CaptureToastOverlayView(model: model))
    private lazy var editorHostingController = NSHostingController(rootView: PackEditorOverlayView(model: model))

    private lazy var toastPanel: ClipboardOverlayPanel = {
        let panel = ClipboardOverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 180),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = toastHostingController
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        return panel
    }()

    private lazy var editorPanel: ClipboardOverlayPanel = {
        let panel = ClipboardOverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 700),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = editorHostingController
        panel.delegate = self
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .moveToActiveSpace]
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        return panel
    }()

    init(model: ClipboardStudioModel) {
        self.model = model
    }

    func presentToast() {
        guard model.toastState != nil else {
            dismissToast()
            return
        }

        positionToastPanel()
        toastPanel.orderFrontRegardless()
        scheduleToastDismissal()
    }

    func dismissToast() {
        toastDismissWorkItem?.cancel()
        toastDismissWorkItem = nil
        toastPanel.orderOut(nil)
    }

    func showPackEditor() {
        positionEditorPanel()
        editorPanel.makeKeyAndOrderFront(nil)
    }

    func hidePackEditor() {
        editorPanel.orderOut(nil)
    }

    func togglePackEditor() {
        if editorPanel.isVisible {
            hidePackEditor()
            model.packEditorDidDismissExternally()
        } else {
            showPackEditor()
        }
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as AnyObject? === editorPanel {
            model.packEditorDidDismissExternally()
        }
    }

    private func scheduleToastDismissal() {
        toastDismissWorkItem?.cancel()

        guard let duration = model.toastState?.autoDismissAfter else { return }
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                self?.model.dismissToast()
            }
        }
        toastDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func positionToastPanel() {
        let visibleFrame = NSScreen.main?.visibleFrame ?? .zero
        let panelSize = toastPanel.frame.size
        let origin = NSPoint(
            x: visibleFrame.maxX - panelSize.width - 22,
            y: visibleFrame.maxY - panelSize.height - 28
        )
        toastPanel.setFrameOrigin(origin)
    }

    private func positionEditorPanel() {
        let visibleFrame = NSScreen.main?.visibleFrame ?? .zero
        let panelSize = editorPanel.frame.size
        let origin = NSPoint(
            x: min(
                max(visibleFrame.midX - (panelSize.width / 2), visibleFrame.minX + 20),
                visibleFrame.maxX - panelSize.width - 20
            ),
            y: min(
                max(visibleFrame.midY - (panelSize.height / 2), visibleFrame.minY + 20),
                visibleFrame.maxY - panelSize.height - 20
            )
        )
        editorPanel.setFrameOrigin(origin)
    }
}
