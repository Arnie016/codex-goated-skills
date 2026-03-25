import AppKit
import Carbon
import Foundation

@MainActor
final class ClipboardStudioModel: ObservableObject {
    private enum DefaultsKey {
        static let historyStore = "clipboardStudio.historyStore"
        static let contextPack = "clipboardStudio.contextPack"
        static let packObjective = "clipboardStudio.packObjective"
        static let privateMode = "clipboardStudio.privateMode"
    }

    private enum Limits {
        static let historyCount = 60
        static let maxPersistedCharacters = 20_000
    }

    private enum CaptureDestination {
        case pack
        case history
    }

    @Published var searchText = ""
    @Published var packObjective = "" {
        didSet {
            defaults.set(packObjective, forKey: DefaultsKey.packObjective)
        }
    }
    @Published private(set) var historyStore = ClipboardHistoryStore()
    @Published private(set) var contextPack = ContextPack()
    @Published private(set) var headline = "Ready To Capture Context"
    @Published private(set) var subheadline = "Capture code, logs, and notes with hotkeys, then send one AI-ready pack back into your app."
    @Published private(set) var statusTone: StatusTone = .ready
    @Published private(set) var accessibilityTrusted = ClipboardAutomationService.isTrusted()
    @Published private(set) var lastSendResult: LastSendResult?
    @Published private(set) var toastState: PackToastState?
    @Published private(set) var isPackEditorPresented = false
    @Published var isPrivateMode = false {
        didSet {
            defaults.set(isPrivateMode, forKey: DefaultsKey.privateMode)
            if isPrivateMode {
                headline = "Private Mode On"
                subheadline = "Passive clipboard history is paused. Explicit captures still go into the pack."
                statusTone = .paused
            } else {
                headline = "Clipboard Monitoring On"
                subheadline = "Passive clipboard history is live again."
                statusTone = .ready
            }
        }
    }

    enum StatusTone {
        case ready
        case working
        case success
        case paused
        case warning
        case failure

        var color: NSColor {
            switch self {
            case .ready: return NSColor(calibratedRed: 0.47, green: 0.83, blue: 0.63, alpha: 1)
            case .working: return NSColor(calibratedRed: 0.43, green: 0.72, blue: 0.98, alpha: 1)
            case .success: return NSColor(calibratedRed: 0.36, green: 0.88, blue: 0.57, alpha: 1)
            case .paused: return NSColor(calibratedRed: 0.77, green: 0.77, blue: 0.84, alpha: 1)
            case .warning: return NSColor(calibratedRed: 0.98, green: 0.75, blue: 0.34, alpha: 1)
            case .failure: return NSColor(calibratedRed: 0.98, green: 0.52, blue: 0.43, alpha: 1)
            }
        }
    }

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var pasteboardPollTimer: Timer?
    private var observedPasteboardChangeCount: Int
    private var lastExternalApplication: NSRunningApplication?
    private var activationObserver: NSObjectProtocol?
    private var hotKeyMonitor: GlobalHotKeyMonitor?
    private var overlayCoordinator: InstantContextPackOverlayCoordinator?
    private var lastUndoablePackItemID: UUID?

    init() {
        self.observedPasteboardChangeCount = NSPasteboard.general.changeCount
        restoreState()
        beginObservingActiveApplications()
        beginMonitoringPasteboard()
        overlayCoordinator = InstantContextPackOverlayCoordinator(model: self)
        configureHotKeys()
        refreshAmbientStatus()
    }

    var hasPack: Bool {
        !contextPack.isEmpty
    }

    var menuBarHelpText: String {
        if hasPack {
            let lastTarget = lastSendResult?.targetAppName.map { " • last to \($0)" } ?? ""
            return "Clipboard Studio • \(contextPack.count) pack item\(contextPack.count == 1 ? "" : "s") ready\(lastTarget)"
        }

        if let lastSendResult {
            return "Clipboard Studio • \(lastSendResult.label)"
        }

        return "Clipboard Studio • Ready for \(ClipboardStudioShortcut.captureSelection.keyChord)"
    }

    var filteredHistory: [ClipboardEntry] {
        historyStore.filtered(matching: searchText)
    }

    var pinnedEntries: [ClipboardEntry] {
        filteredHistory.filter(\.isPinned)
    }

    var recentEntries: [ClipboardEntry] {
        filteredHistory.filter { !$0.isPinned }
    }

    var targetAppLabel: String {
        currentTargetApplication()?.localizedName ?? "No app yet"
    }

    var formattedPackPreview: String {
        ContextPackFormatter.format(objective: packObjective, pack: contextPack)
    }

    func togglePin(for entry: ClipboardEntry) {
        historyStore.togglePin(id: entry.id)
        persistHistoryState()
    }

    func removePackItem(_ item: PackItem) {
        contextPack.remove(id: item.id)
        persistPackState()
        if contextPack.isEmpty {
            refreshAmbientStatus()
        }
    }

    func clearPack() {
        contextPack.clear()
        lastUndoablePackItemID = nil
        dismissToast()
        headline = "Pack Cleared"
        subheadline = "Start capturing fresh context for the next prompt."
        statusTone = .ready
        persistPackState()
    }

    func clearHistory() {
        historyStore.clear()
        headline = "History Cleared"
        subheadline = "Passive clipboard history will refill as you keep working."
        statusTone = .ready
        persistHistoryState()
    }

    func copyEntry(_ entry: ClipboardEntry) {
        setClipboardText(entry.text)
        headline = "Clip Copied"
        subheadline = "Moved the selected history item back onto the clipboard."
        statusTone = .success
    }

    func copyCurrentPackToClipboard() {
        guard let formattedPack = currentFormattedPack() else {
            headline = "Pack Empty"
            subheadline = "Capture a few clips before copying the prompt pack."
            statusTone = .warning
            return
        }

        setClipboardText(formattedPack)
        headline = "Pack Copied"
        subheadline = "The AI prompt pack is now on your clipboard."
        statusTone = .success
    }

    func addLatestClipToPack() {
        guard let latest = historyStore.entries.first else {
            headline = "Nothing To Add Yet"
            subheadline = "Copy some text first or grab selection from your IDE."
            statusTone = .warning
            return
        }
        addToPack(entry: latest)
    }

    func addToPack(entry: ClipboardEntry) {
        switch contextPack.insert(entry: entry) {
        case let .added(item):
            lastUndoablePackItemID = item.id
            headline = "Added To Pack"
            subheadline = "That history item is now part of the AI prompt pack."
            statusTone = .success
            persistPackState()
            presentToast(
                PackToastState(
                    kind: .capture,
                    title: "Captured Into Pack",
                    detail: "Packed from \(entry.sourceAppName ?? "history") and ready to send.",
                    preview: item.previewLine,
                    sourceAppName: item.sourceAppName,
                    packCount: contextPack.count,
                    undoItemID: item.id,
                    autoDismissAfter: 3.2
                )
            )
        case let .duplicate(item):
            headline = "Already In Pack"
            subheadline = "That exact clip is already in the current prompt pack."
            statusTone = .warning
            presentToast(
                PackToastState(
                    kind: .duplicate,
                    title: "Already In Pack",
                    detail: "Skipped a duplicate clip to keep the prompt pack clean.",
                    preview: item.previewLine,
                    sourceAppName: item.sourceAppName,
                    packCount: contextPack.count,
                    undoItemID: nil,
                    autoDismissAfter: 2.8
                )
            )
        }
    }

    func pasteEntry(_ entry: ClipboardEntry) {
        Task {
            await pasteClip(
                entry.text,
                successHeadline: "Clip Pasted",
                successDetail: "Sent that clip back into \(targetAppLabel)."
            )
        }
    }

    func sendCurrentPack() {
        Task {
            await sendCurrentPackToTarget()
        }
    }

    func captureSelectionIntoPack() {
        Task {
            await captureSelection(destination: .pack)
        }
    }

    func captureSelectionToHistory() {
        Task {
            await captureSelection(destination: .history)
        }
    }

    func undoLastPackAddition() {
        guard let lastUndoablePackItemID,
              let removedItem = contextPack.remove(id: lastUndoablePackItemID) else {
            dismissToast()
            return
        }

        headline = "Capture Undone"
        subheadline = "Removed \(removedItem.sourceAppName ?? "that clip") from the current prompt pack."
        statusTone = .ready
        self.lastUndoablePackItemID = nil
        persistPackState()
        dismissToast()
    }

    func openPackEditor() {
        isPackEditorPresented = true
        overlayCoordinator?.showPackEditor()
    }

    func closePackEditor() {
        isPackEditorPresented = false
        overlayCoordinator?.hidePackEditor()
    }

    func packEditorDidDismissExternally() {
        isPackEditorPresented = false
    }

    func dismissToast() {
        toastState = nil
        overlayCoordinator?.dismissToast()
    }

    func promptForAccessibilityAccess() {
        accessibilityTrusted = ClipboardAutomationService.isTrusted()

        guard !accessibilityTrusted else {
            headline = "Accessibility Ready"
            subheadline = "Direct capture and send can talk to your focused apps now."
            statusTone = .success
            return
        }

        accessibilityTrusted = ClipboardAutomationService.promptForTrust()
        if accessibilityTrusted {
            headline = "Accessibility Ready"
            subheadline = "Direct capture and send can talk to your focused apps now."
            statusTone = .success
        } else {
            headline = "Accessibility Needed"
            subheadline = "Allow Clipboard Studio in System Settings, then reopen the app if macOS still blocks direct capture."
            statusTone = .warning
        }
    }

    func quit() {
        NSApp.terminate(nil)
    }

    private func captureSelection(destination: CaptureDestination) async {
        guard let targetApp = currentTargetApplication() else {
            headline = "No Target App Yet"
            subheadline = "Open your IDE, terminal, or browser first, then try again."
            statusTone = .warning
            return
        }

        accessibilityTrusted = ClipboardAutomationService.isTrusted()
        guard accessibilityTrusted else {
            headline = "Enable Accessibility"
            subheadline = "Clipboard Studio needs Accessibility to capture from \(targetApp.localizedName ?? "that app")."
            statusTone = .warning
            presentToast(
                PackToastState(
                    kind: .error,
                    title: "Need Accessibility",
                    detail: "Capture needs Accessibility. Use the Permissions button if you want Clipboard Studio to ask macOS again.",
                    preview: "If Clipboard Studio is already enabled, quit and reopen it, then try \(ClipboardStudioShortcut.captureSelection.keyChord) again.",
                    sourceAppName: targetApp.localizedName,
                    packCount: contextPack.count,
                    undoItemID: nil,
                    autoDismissAfter: 3.4
                )
            )
            return
        }

        accessibilityTrusted = true
        headline = "Capturing Selection..."
        subheadline = "Reading the current selection from \(targetApp.localizedName ?? "your app")."
        statusTone = .working

        do {
            let result = try await ClipboardAutomationService.captureSelection(from: targetApp)
            observedPasteboardChangeCount = NSPasteboard.general.changeCount
            ingestExplicitCapture(
                result.text,
                sourceAppName: targetApp.localizedName,
                destination: destination,
                actionDetail: result.captureMethodDescription
            )
        } catch {
            headline = "Couldn’t Capture Selection"
            subheadline = error.localizedDescription
            statusTone = .failure
            presentToast(
                PackToastState(
                    kind: .error,
                    title: "Capture Failed",
                    detail: error.localizedDescription,
                    preview: "Highlight text in the target app and try \(ClipboardStudioShortcut.captureSelection.keyChord) again.",
                    sourceAppName: targetApp.localizedName,
                    packCount: contextPack.count,
                    undoItemID: nil,
                    autoDismissAfter: 3.2
                )
            )
        }
    }

    private func sendCurrentPackToTarget() async {
        guard let formattedPack = currentFormattedPack() else {
            headline = "Pack Empty"
            subheadline = "Capture a few clips before sending the prompt pack."
            statusTone = .warning
            return
        }

        setClipboardText(formattedPack)

        guard let targetApp = currentTargetApplication() else {
            applyClipboardFallback(
                targetAppName: nil,
                detail: "Copied the prompt pack to the clipboard because there was no frontmost destination app."
            )
            return
        }

        accessibilityTrusted = ClipboardAutomationService.isTrusted()
        guard accessibilityTrusted else {
            applyClipboardFallback(
                targetAppName: targetApp.localizedName,
                detail: "Copied the prompt pack to the clipboard because direct send needs Accessibility permission. Use Permissions if you want macOS to prompt again."
            )
            return
        }

        headline = "Pasting..."
        subheadline = "Sending the prompt pack into \(targetApp.localizedName ?? "your app")."
        statusTone = .working

        do {
            try await ClipboardAutomationService.pasteClipboardContents(into: targetApp)
            lastSendResult = LastSendResult(
                delivery: .directSend,
                targetAppName: targetApp.localizedName,
                detail: "Delivered the prompt pack directly into \(targetApp.localizedName ?? "the target app").",
                timestamp: Date()
            )
            headline = "Pack Sent"
            subheadline = "Delivered the prompt pack directly into \(targetApp.localizedName ?? "the target app")."
            statusTone = .success
            presentToast(
                PackToastState(
                    kind: .directSend,
                    title: "Prompt Sent",
                    detail: "Delivered straight into \(targetApp.localizedName ?? "the target app").",
                    preview: previewLine(for: formattedPack),
                    sourceAppName: targetApp.localizedName,
                    packCount: contextPack.count,
                    undoItemID: nil,
                    autoDismissAfter: 2.8
                )
            )
        } catch {
            applyClipboardFallback(
                targetAppName: targetApp.localizedName,
                detail: "Copied the prompt pack to the clipboard because direct send failed: \(error.localizedDescription)"
            )
        }
    }

    private func pasteClip(
        _ text: String,
        successHeadline: String,
        successDetail: String
    ) async {
        setClipboardText(text)

        guard let targetApp = currentTargetApplication() else {
            headline = "Clip Copied"
            subheadline = "There was no target app, so the clip is ready on your clipboard instead."
            statusTone = .warning
            return
        }

        accessibilityTrusted = ClipboardAutomationService.isTrusted()
        guard accessibilityTrusted else {
            headline = "Clip Copied"
            subheadline = "Direct paste needs Accessibility. The clip is ready on your clipboard instead. Use Permissions if you want macOS to prompt again."
            statusTone = .warning
            return
        }

        do {
            try await ClipboardAutomationService.pasteClipboardContents(into: targetApp)
            headline = successHeadline
            subheadline = successDetail
            statusTone = .success
        } catch {
            headline = "Clip Copied"
            subheadline = "Direct paste failed, so the clip is ready on your clipboard instead."
            statusTone = .warning
        }
    }

    private func ingestExplicitCapture(
        _ text: String,
        sourceAppName: String?,
        destination: CaptureDestination,
        actionDetail: String
    ) {
        guard let normalized = normalizedText(from: text) else {
            headline = "Empty Selection"
            subheadline = "There was no usable text in the current selection."
            statusTone = .warning
            return
        }

        let entry = historyStore.record(text: normalized, sourceAppName: sourceAppName, limit: Limits.historyCount)
        persistHistoryState()

        guard destination == .pack else {
            headline = "Selection Captured"
            subheadline = "\(actionDetail) from \(sourceAppName ?? "the active app") and saved it to history."
            statusTone = .success
            presentToast(
                PackToastState(
                    kind: .capture,
                    title: "Saved To History",
                    detail: "\(actionDetail) from \(sourceAppName ?? "the active app").",
                    preview: previewLine(for: normalized),
                    sourceAppName: sourceAppName,
                    packCount: contextPack.count,
                    undoItemID: nil,
                    autoDismissAfter: 2.6
                )
            )
            return
        }

        switch contextPack.insert(text: entry.text, sourceAppName: sourceAppName) {
        case let .added(item):
            lastUndoablePackItemID = item.id
            headline = "Selection Added To Pack"
            subheadline = "\(actionDetail) from \(sourceAppName ?? "the active app") and packed it for instant send."
            statusTone = .success
            persistPackState()
            presentToast(
                PackToastState(
                    kind: .capture,
                    title: "Captured Into Pack",
                    detail: "Packed from \(sourceAppName ?? "the active app") and ready for \(ClipboardStudioShortcut.sendPack.keyChord).",
                    preview: item.previewLine,
                    sourceAppName: item.sourceAppName,
                    packCount: contextPack.count,
                    undoItemID: item.id,
                    autoDismissAfter: 3.2
                )
            )
        case let .duplicate(existing):
            headline = "Already In Pack"
            subheadline = "That exact selection was already captured, so the pack stayed clean."
            statusTone = .warning
            presentToast(
                PackToastState(
                    kind: .duplicate,
                    title: "Already In Pack",
                    detail: "Skipped a duplicate capture from \(sourceAppName ?? "the active app").",
                    preview: existing.previewLine,
                    sourceAppName: existing.sourceAppName,
                    packCount: contextPack.count,
                    undoItemID: nil,
                    autoDismissAfter: 2.8
                )
            )
        }
    }

    private func normalizedText(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.count > Limits.maxPersistedCharacters {
            return String(trimmed.prefix(Limits.maxPersistedCharacters))
        }
        return trimmed
    }

    private func setClipboardText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        observedPasteboardChangeCount = pasteboard.changeCount
    }

    private func beginMonitoringPasteboard() {
        pasteboardPollTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollPasteboard()
            }
        }
        if let pasteboardPollTimer {
            RunLoop.main.add(pasteboardPollTimer, forMode: .common)
        }
    }

    private func pollPasteboard() {
        guard !isPrivateMode else { return }

        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != observedPasteboardChangeCount else { return }
        observedPasteboardChangeCount = pasteboard.changeCount

        guard let raw = pasteboard.string(forType: .string),
              let normalized = normalizedText(from: raw) else {
            return
        }

        let sourceAppName = currentTargetApplication()?.localizedName
        _ = historyStore.record(text: normalized, sourceAppName: sourceAppName, limit: Limits.historyCount)
        persistHistoryState()
    }

    private func beginObservingActiveApplications() {
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.bundleIdentifier != Bundle.main.bundleIdentifier {
            lastExternalApplication = frontmost
        }

        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier != Bundle.main.bundleIdentifier else {
                return
            }

            Task { @MainActor [weak self] in
                self?.lastExternalApplication = app
            }
        }
    }

    private func currentTargetApplication() -> NSRunningApplication? {
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.bundleIdentifier != Bundle.main.bundleIdentifier {
            return frontmost
        }
        return lastExternalApplication
    }

    private func restoreState() {
        isPrivateMode = defaults.bool(forKey: DefaultsKey.privateMode)
        packObjective = defaults.string(forKey: DefaultsKey.packObjective) ?? ""

        if let data = defaults.data(forKey: DefaultsKey.historyStore),
           let decoded = try? decoder.decode(ClipboardHistoryStore.self, from: data) {
            historyStore = decoded
        }

        if let data = defaults.data(forKey: DefaultsKey.contextPack),
           let decoded = try? decoder.decode(ContextPack.self, from: data) {
            contextPack = decoded
        }
    }

    private func persistHistoryState() {
        if let data = try? encoder.encode(historyStore) {
            defaults.set(data, forKey: DefaultsKey.historyStore)
        }
    }

    private func persistPackState() {
        if let data = try? encoder.encode(contextPack) {
            defaults.set(data, forKey: DefaultsKey.contextPack)
        }
    }

    private func configureHotKeys() {
        let monitor = GlobalHotKeyMonitor()
        let modifiers = UInt32(controlKey | optionKey)

        monitor.register(action: .captureSelection, keyCode: UInt32(kVK_ANSI_C), modifiers: modifiers) { [weak self] in
            Task { @MainActor [weak self] in
                self?.captureSelectionIntoPack()
            }
        }

        monitor.register(action: .sendPack, keyCode: UInt32(kVK_ANSI_V), modifiers: modifiers) { [weak self] in
            Task { @MainActor [weak self] in
                self?.sendCurrentPack()
            }
        }

        monitor.register(action: .openPack, keyCode: UInt32(kVK_ANSI_P), modifiers: modifiers) { [weak self] in
            Task { @MainActor [weak self] in
                self?.togglePackEditor()
            }
        }

        hotKeyMonitor = monitor
    }

    private func togglePackEditor() {
        if isPackEditorPresented {
            closePackEditor()
        } else {
            openPackEditor()
        }
    }

    private func currentFormattedPack() -> String? {
        let formattedPack = formattedPackPreview.trimmingCharacters(in: .whitespacesAndNewlines)
        return formattedPack.isEmpty ? nil : formattedPack
    }

    private func previewLine(for text: String) -> String {
        let firstLine = text
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !firstLine.isEmpty else { return "Prompt pack ready" }
        return String(firstLine.prefix(96))
    }

    private func applyClipboardFallback(targetAppName: String?, detail: String) {
        lastSendResult = LastSendResult(
            delivery: .clipboardFallback,
            targetAppName: targetAppName,
            detail: detail,
            timestamp: Date()
        )
        headline = "Pack Copied Instead"
        subheadline = detail
        statusTone = .warning
        presentToast(
            PackToastState(
                kind: .fallback,
                title: "Clipboard Fallback",
                detail: detail,
                preview: previewLine(for: formattedPackPreview),
                sourceAppName: targetAppName,
                packCount: contextPack.count,
                undoItemID: nil,
                autoDismissAfter: 3.4
            )
        )
    }

    private func presentToast(_ state: PackToastState) {
        toastState = state
        overlayCoordinator?.presentToast()
    }

    private func refreshAmbientStatus() {
        accessibilityTrusted = ClipboardAutomationService.isTrusted()

        guard !contextPack.isEmpty else { return }
        headline = "Prompt Pack Ready"
        subheadline = "\(contextPack.count) captured clip\(contextPack.count == 1 ? "" : "s") ready for \(ClipboardStudioShortcut.sendPack.keyChord)."
        statusTone = .ready
    }
}
