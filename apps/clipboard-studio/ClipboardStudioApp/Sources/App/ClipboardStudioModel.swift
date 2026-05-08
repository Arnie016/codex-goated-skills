import AppKit
import Carbon
import Foundation

@MainActor
final class ClipboardStudioModel: ObservableObject {
    private enum DefaultsKey {
        static let historyStore = "clipboardStudio.historyStore"
        static let focusHistoryStore = "clipboardStudio.focusHistoryStore"
        static let currentFocusSnapshot = "clipboardStudio.currentFocusSnapshot"
        static let contextPack = "clipboardStudio.contextPack"
        static let packObjective = "clipboardStudio.packObjective"
        static let privateMode = "clipboardStudio.privateMode"
        static let markdownExportFolderPath = "clipboardStudio.markdownExportFolderPath"
        static let keepAssemblyWindowVisible = "clipboardStudio.keepAssemblyWindowVisible"
    }

    private enum Limits {
        static let historyCount = 60
        static let focusHistoryCount = 18
        static let maxPersistedCharacters = 20_000
    }

    private enum Secrets {
        static let service = "com.arnav.ContextAssembly"
        static let openAIKey = "openai.apiKey"
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
    @Published private(set) var focusHistoryStore = FocusHistoryStore()
    @Published private(set) var contextPack = ContextPack()
    @Published private(set) var currentFocusSnapshot: FocusSnapshot?
    @Published private(set) var headline = "Ready To Assemble Context"
    @Published private(set) var subheadline = "Capture code, logs, and notes, then send or export one structured assembly."
    @Published private(set) var statusTone: StatusTone = .ready
    @Published private(set) var accessibilityTrusted = ClipboardAutomationService.isTrusted()
    @Published private(set) var lastSendResult: LastSendResult?
    @Published private(set) var toastState: PackToastState?
    @Published private(set) var isPackEditorPresented = false
    @Published private(set) var markdownExportFolderPath: String?
    @Published private(set) var hasStoredOpenAIKey = false
    @Published private(set) var isResearching = false
    @Published var openAIKeyInput = ""
    @Published var keepsAssemblyWindowVisible = true {
        didSet {
            defaults.set(keepsAssemblyWindowVisible, forKey: DefaultsKey.keepAssemblyWindowVisible)
            overlayCoordinator?.refreshEditorPanelBehavior()
            if keepsAssemblyWindowVisible, isPackEditorPresented {
                overlayCoordinator?.showPackEditor()
            }
        }
    }
    @Published var isPrivateMode = false {
        didSet {
            defaults.set(isPrivateMode, forKey: DefaultsKey.privateMode)
            if isPrivateMode {
                headline = "Private Mode On"
                subheadline = "Passive clipboard history is paused. Explicit captures still go into the assembly."
                statusTone = .paused
            } else {
                headline = "History Live"
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
    private let keychain = KeychainStore(service: Secrets.service)
    private let researchService = ContextAssemblyResearchService()
    private var pasteboardPollTimer: Timer?
    private var focusPollTimer: Timer?
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
        beginMonitoringCurrentFocus()
        overlayCoordinator = InstantContextPackOverlayCoordinator(model: self)
        configureHotKeys()
        refreshOpenAIKeyStatus()
        refreshCurrentFocus(recordInHistory: currentFocusSnapshot == nil)
        refreshAmbientStatus()
    }

    var hasPack: Bool {
        !contextPack.isEmpty
    }

    var menuBarHelpText: String {
        if hasPack {
            let lastTarget = lastSendResult?.targetAppName.map { " • last to \($0)" } ?? ""
            return "\(ContextAssemblyBrand.appName) • \(contextPack.count) capture\(contextPack.count == 1 ? "" : "s") ready\(lastTarget)"
        }

        if let currentFocusSnapshot {
            return "\(ContextAssemblyBrand.appName) • \(currentFocusSnapshot.statusLabel) from \(currentFocusSnapshot.sourceLabel)"
        }

        if let lastSendResult {
            return "\(ContextAssemblyBrand.appName) • \(lastSendResult.label)"
        }

        return "\(ContextAssemblyBrand.appName) • Ready for \(ClipboardStudioShortcut.captureSelection.keyChord)"
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

    var filteredFocusStates: [FocusSnapshot] {
        focusHistoryStore.filtered(matching: searchText)
    }

    var recentFocusStates: [FocusSnapshot] {
        Array(filteredFocusStates.prefix(6))
    }

    var targetAppLabel: String {
        currentTargetApplication()?.localizedName ?? "No app yet"
    }

    var sendActionTitle: String {
        if let targetApp = currentTargetApplication()?.localizedName,
           !targetApp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           targetApp.count <= 16 {
            return "Paste To \(targetApp)"
        }
        return "Paste To Target"
    }

    var hasAnyOpenAIKey: Bool {
        !(availableOpenAIKey ?? "").isEmpty
    }

    var formattedPackPreview: String {
        ContextPackFormatter.format(objective: packObjective, pack: contextPack)
    }

    var assemblyTimelineItems: [PackItem] {
        contextPack.timelineItems
    }

    var markdownExportActionTitle: String {
        if let markdownExportFolderName {
            return "Save Markdown to \(markdownExportFolderName)"
        }
        return "Save Markdown..."
    }

    var markdownExportFolderName: String? {
        guard let markdownExportFolderPath else { return nil }
        return URL(fileURLWithPath: markdownExportFolderPath).lastPathComponent
    }

    var currentFocusCardTitle: String {
        currentFocusSnapshot?.primaryTitle ?? "No current app state yet"
    }

    private var availableOpenAIKey: String? {
        let environmentKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !environmentKey.isEmpty {
            return environmentKey
        }

        let storedKey = (try? keychain.read(account: Secrets.openAIKey))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return storedKey.isEmpty ? nil : storedKey
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
        headline = "Assembly Cleared"
        subheadline = "Start capturing fresh context for the next assembly."
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
            headline = "Assembly Empty"
            subheadline = "Capture a few clips before copying the assembly."
            statusTone = .warning
            return
        }

        setClipboardText(formattedPack)
        headline = "Assembly Copied"
        subheadline = "The structured assembly is now on your clipboard."
        statusTone = .success
    }

    func exportAssemblyToNotes() {
        guard let payload = currentAssemblyExportPayload() else { return }

        do {
            try ContextAssemblyExportService.exportToNotes(title: payload.title, document: payload.document)
            headline = "Exported To Notes"
            subheadline = "Saved \"\(payload.title)\" to Apple Notes."
            statusTone = .success
        } catch {
            headline = "Notes Export Failed"
            subheadline = error.localizedDescription
            statusTone = .failure
        }
    }

    func exportAssemblyMarkdown() {
        guard let payload = currentAssemblyExportPayload() else { return }
        guard let folderURL = resolvedMarkdownExportFolderURL(promptIfNeeded: true) else { return }

        do {
            let fileURL = try ContextAssemblyExportService.exportMarkdown(
                document: payload.document,
                title: payload.title,
                to: folderURL
            )
            headline = "Markdown Saved"
            subheadline = "Saved \(fileURL.lastPathComponent) to \(folderURL.lastPathComponent)."
            statusTone = .success
        } catch {
            headline = "Markdown Export Failed"
            subheadline = error.localizedDescription
            statusTone = .failure
        }
    }

    func chooseMarkdownExportFolder() {
        guard let folderURL = promptForMarkdownExportFolder() else { return }
        storeMarkdownExportFolder(folderURL)
        headline = "Markdown Folder Saved"
        subheadline = "Future exports will go straight to \(folderURL.lastPathComponent)."
        statusTone = .success
    }

    func refreshCurrentFocusManually() {
        refreshCurrentFocus(force: true, recordInHistory: true)
        if let currentFocusSnapshot {
            headline = "Current Focus Refreshed"
            subheadline = "Updated the saved state from \(currentFocusSnapshot.sourceLabel)."
            statusTone = .success
        } else {
            headline = "No Current Focus Yet"
            subheadline = "Bring another app to the front, then refresh again."
            statusTone = .warning
        }
    }

    func refreshCurrentFocusSilently() {
        refreshCurrentFocus(force: true, recordInHistory: true)
    }

    func clearFocusHistory() {
        focusHistoryStore.clear()
        persistFocusHistoryState()
        headline = "Recent States Cleared"
        subheadline = "New browser pages and document states will appear as you keep working."
        statusTone = .ready
    }

    func addCurrentFocusToPack() {
        guard let currentFocusSnapshot else {
            headline = "No Current Focus Yet"
            subheadline = "Refresh the current app state first, then add it to the assembly."
            statusTone = .warning
            return
        }

        addFocusSnapshotToPack(currentFocusSnapshot)
    }

    func addCurrentSelectionToPack() {
        guard let selection = currentSelectionText(),
              let snapshot = currentFocusSnapshot else {
            headline = "No Live Selection Yet"
            subheadline = "Highlight text in the frontmost app and it will appear here."
            statusTone = .warning
            return
        }

        let now = Date()
        let entry = historyStore.record(
            text: selection,
            sourceAppName: snapshot.sourceLabel,
            limit: Limits.historyCount,
            createdAt: now
        )
        persistHistoryState()
        addToPack(entry: entry)
        refreshCurrentFocus(force: true, preferredSelection: selection, recordInHistory: true)
    }

    func saveCurrentSelectionToHistory() {
        guard let selection = currentSelectionText(),
              let snapshot = currentFocusSnapshot else {
            headline = "No Live Selection Yet"
            subheadline = "Highlight text in the frontmost app and it will appear here."
            statusTone = .warning
            return
        }

        _ = historyStore.record(
            text: selection,
            sourceAppName: snapshot.sourceLabel,
            limit: Limits.historyCount,
            createdAt: Date()
        )
        persistHistoryState()
        headline = "Selection Saved"
        subheadline = "Saved the live selection from \(snapshot.sourceLabel) into history."
        statusTone = .success
    }

    func copyCurrentSelection() {
        guard let selection = currentSelectionText(),
              let snapshot = currentFocusSnapshot else {
            headline = "No Live Selection Yet"
            subheadline = "Highlight text in the frontmost app and it will appear here."
            statusTone = .warning
            return
        }

        setClipboardText(selection)
        headline = "Selection Copied"
        subheadline = "Copied the live selection from \(snapshot.sourceLabel)."
        statusTone = .success
    }

    func mergeCurrentSelectionWithLatestItem() {
        guard let selection = currentSelectionText(),
              let snapshot = currentFocusSnapshot else {
            headline = "No Live Selection Yet"
            subheadline = "Highlight text in the frontmost app and it will appear here."
            statusTone = .warning
            return
        }

        guard let latest = contextPack.items.first else {
            headline = "Assembly Empty"
            subheadline = "Add at least one assembly step before merging the live selection."
            statusTone = .warning
            return
        }

        let mergedText = """
        ## Selected Right Now
        \(selection)

        ## Existing Assembly Step
        \(latest.text)
        """

        contextPack.items[0] = PackItem(
            id: latest.id,
            text: mergedText,
            sourceAppName: "\(snapshot.sourceLabel) + \(latest.sourceLabel)",
            capturedAt: Date()
        )
        persistPackState()
        headline = "Live Selection Merged"
        subheadline = "Merged the current selection with the newest assembly step."
        statusTone = .success
    }

    func addFocusSnapshotToPack(_ snapshot: FocusSnapshot) {
        currentFocusSnapshot = snapshot
        persistCurrentFocusState()

        switch contextPack.insert(text: snapshot.assemblyText, sourceAppName: snapshot.sourceLabel, capturedAt: snapshot.capturedAt) {
        case let .added(item):
            lastUndoablePackItemID = item.id
            headline = "State Added"
            subheadline = "Saved the current state from \(snapshot.sourceLabel) into the assembly."
            statusTone = .success
            persistPackState()
            presentToast(
                PackToastState(
                    kind: .capture,
                    title: "State Added",
                    detail: "Added the current state from \(snapshot.sourceLabel).",
                    preview: snapshot.primaryTitle,
                    sourceAppName: snapshot.sourceLabel,
                    packCount: contextPack.count,
                    undoItemID: item.id,
                    autoDismissAfter: 3.2
                )
            )
        case .duplicate:
            headline = "State Already Added"
            subheadline = "That exact app state is already part of this assembly."
            statusTone = .warning
        }
    }

    func copyCurrentFocus() {
        guard let currentFocusSnapshot else {
            headline = "No Current Focus Yet"
            subheadline = "Refresh the current app state first, then copy it."
            statusTone = .warning
            return
        }
        copyFocusSnapshot(currentFocusSnapshot)
    }

    func copyFocusSnapshot(_ snapshot: FocusSnapshot) {
        setClipboardText(snapshot.assemblyText)
        currentFocusSnapshot = snapshot
        persistCurrentFocusState()
        headline = "State Copied"
        subheadline = "Copied the saved state from \(snapshot.sourceLabel) to the clipboard."
        statusTone = .success
    }

    func resumeCurrentFocus() {
        guard let currentFocusSnapshot else {
            headline = "No Current Focus Yet"
            subheadline = "There is no saved page or app state to resume yet."
            statusTone = .warning
            return
        }
        resumeFocusSnapshot(currentFocusSnapshot)
    }

    func resumeFocusSnapshot(_ snapshot: FocusSnapshot) {
        currentFocusSnapshot = snapshot
        persistCurrentFocusState()

        if CurrentContextSnapshotService.resume(snapshot) {
            headline = "State Resumed"
            subheadline = snapshot.urlString == nil
                ? "Brought \(snapshot.sourceLabel) back to the front."
                : "Reopened the saved page from \(snapshot.sourceLabel)."
            statusTone = .success
        } else {
            headline = "Couldn't Resume State"
            subheadline = "That saved app state could not be reopened automatically."
            statusTone = .failure
        }
    }

    func useFocusSnapshot(_ snapshot: FocusSnapshot) {
        currentFocusSnapshot = snapshot
        persistCurrentFocusState()
        addFocusSnapshotToPack(snapshot)
    }

    func mergeCurrentFocusWithLatestItem() {
        guard let currentFocusSnapshot else {
            headline = "No Current Focus Yet"
            subheadline = "Refresh or capture the current state first, then merge it."
            statusTone = .warning
            return
        }

        guard let latest = contextPack.items.first else {
            headline = "Assembly Empty"
            subheadline = "Add at least one assembly step before merging the current state."
            statusTone = .warning
            return
        }

        let mergedText = """
        ## Current Focus
        \(currentFocusSnapshot.assemblyText)

        ## Existing Assembly Step
        \(latest.text)
        """

        contextPack.items[0] = PackItem(
            id: latest.id,
            text: mergedText,
            sourceAppName: "\(currentFocusSnapshot.sourceLabel) + \(latest.sourceLabel)",
            capturedAt: Date()
        )
        persistPackState()
        headline = "Merged With Latest Step"
        subheadline = "Combined the current focus with the newest assembly step."
        statusTone = .success
    }

    func mergeLatestAssemblySteps() {
        guard contextPack.items.count >= 2 else {
            headline = "Need Two Steps"
            subheadline = "Capture or add two assembly steps before merging."
            statusTone = .warning
            return
        }

        let newest = contextPack.items[0]
        let previous = contextPack.items[1]
        let mergedText = """
        ## Step From \(previous.sourceLabel)
        \(previous.text)

        ## Step From \(newest.sourceLabel)
        \(newest.text)
        """

        let mergedItem = PackItem(
            text: mergedText,
            sourceAppName: "\(previous.sourceLabel) + \(newest.sourceLabel)",
            capturedAt: Date()
        )
        contextPack.items.removeFirst(2)
        contextPack.items.insert(mergedItem, at: 0)
        persistPackState()
        headline = "Latest Steps Merged"
        subheadline = "Combined the top two assembly steps into one cleaner block."
        statusTone = .success
    }

    func saveOpenAIKey() {
        let trimmed = openAIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            headline = "Add Your OpenAI Key"
            subheadline = "Paste a valid OpenAI API key before saving."
            statusTone = .warning
            return
        }

        do {
            try keychain.write(trimmed, account: Secrets.openAIKey)
            openAIKeyInput = ""
            refreshOpenAIKeyStatus()
            headline = "OpenAI Key Saved"
            subheadline = "AI research is ready for current pages, clips, and selections."
            statusTone = .success
        } catch {
            headline = "Couldn't Save OpenAI Key"
            subheadline = error.localizedDescription
            statusTone = .failure
        }
    }

    func clearStoredOpenAIKey() {
        do {
            try keychain.delete(account: Secrets.openAIKey)
            refreshOpenAIKeyStatus()
            headline = "Stored OpenAI Key Removed"
            subheadline = "AI research will now use OPENAI_API_KEY from the environment if it exists."
            statusTone = .ready
        } catch {
            headline = "Couldn't Remove OpenAI Key"
            subheadline = error.localizedDescription
            statusTone = .failure
        }
    }

    func researchCurrentFocus() {
        guard let currentFocusSnapshot else {
            headline = "No Current Focus Yet"
            subheadline = "Refresh the current state first, then run research on it."
            statusTone = .warning
            return
        }

        guard let apiKey = availableOpenAIKey, !apiKey.isEmpty else {
            headline = "Add Your OpenAI Key"
            subheadline = "Save an API key in Settings to turn on the research agent."
            statusTone = .warning
            openSettings()
            return
        }

        Task {
            isResearching = true
            headline = "Researching Current Focus..."
            subheadline = "Creating a compact research brief for \(currentFocusSnapshot.sourceLabel)."
            statusTone = .working

            do {
                let research = try await researchService.research(
                    focus: currentFocusSnapshot,
                    objective: packObjective,
                    apiKey: apiKey
                )
                isResearching = false

                let now = Date()
                let researchEntry = historyStore.record(
                    text: research,
                    sourceAppName: "OpenAI Research",
                    limit: Limits.historyCount,
                    createdAt: now
                )
                persistHistoryState()

                switch contextPack.insert(entry: researchEntry, capturedAt: now) {
                case .added:
                    persistPackState()
                case .duplicate:
                    break
                }

                headline = "Research Added"
                subheadline = "Added an AI research brief to history and the active assembly."
                statusTone = .success
            } catch {
                isResearching = false
                headline = "Research Failed"
                subheadline = error.localizedDescription
                statusTone = .failure
            }
        }
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
        switch contextPack.insert(entry: entry, capturedAt: entry.createdAt) {
        case let .added(item):
            lastUndoablePackItemID = item.id
            headline = "Added To Assembly"
            subheadline = "Added a saved capture from \(entry.sourceLabel) into the active assembly."
            statusTone = .success
            persistPackState()
            presentToast(
                PackToastState(
                    kind: .capture,
                    title: "Added To Assembly",
                    detail: "Added from \(entry.sourceLabel) and ready to send.",
                    preview: item.previewLine,
                    sourceAppName: item.sourceAppName,
                    packCount: contextPack.count,
                    undoItemID: item.id,
                    autoDismissAfter: 3.2
                )
            )
        case let .duplicate(item):
            headline = "Already In Assembly"
            subheadline = "That exact clip is already in the current assembly."
            statusTone = .warning
            presentToast(
                PackToastState(
                    kind: .duplicate,
                    title: "Already In Assembly",
                    detail: "Skipped a duplicate clip to keep the assembly clean.",
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
            await captureSelection(destination: .pack, autoStartAssembly: true)
        }
    }

    func captureSelectionToHistory() {
        Task {
            await captureSelection(destination: .history, autoStartAssembly: false)
        }
    }

    func undoLastPackAddition() {
        guard let lastUndoablePackItemID,
              let removedItem = contextPack.remove(id: lastUndoablePackItemID) else {
            dismissToast()
            return
        }

        headline = "Capture Undone"
        subheadline = "Removed \(removedItem.sourceAppName ?? "that clip") from the current assembly."
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

    func toggleAssemblyWindowVisibilityPin() {
        keepsAssemblyWindowVisible.toggle()
        if keepsAssemblyWindowVisible {
            headline = "Assembly Pinned Live"
            subheadline = "The assembly window will stay visible while you highlight text in other apps."
            statusTone = .success
        } else {
            headline = "Assembly Window Unpinned"
            subheadline = "The assembly window now behaves like a normal floating window."
            statusTone = .ready
        }
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
            refreshCurrentFocus(force: true, recordInHistory: true)
            return
        }

        accessibilityTrusted = ClipboardAutomationService.promptForTrust()
        if accessibilityTrusted {
            headline = "Accessibility Ready"
            subheadline = "Direct capture and send can talk to your focused apps now."
            statusTone = .success
            refreshCurrentFocus(force: true, recordInHistory: true)
        } else {
            headline = "Accessibility Needed"
            subheadline = "Allow \(ContextAssemblyBrand.appName) in System Settings, then reopen the app if macOS still blocks direct capture."
            statusTone = .warning
        }
    }

    func quit() {
        NSApp.terminate(nil)
    }

    private func captureSelection(
        destination: CaptureDestination,
        autoStartAssembly: Bool
    ) async {
        guard let targetApp = currentTargetApplication() else {
            headline = "No Target App Yet"
            subheadline = "Open your IDE, terminal, or browser first, then try again."
            statusTone = .warning
            return
        }

        accessibilityTrusted = ClipboardAutomationService.isTrusted()
        guard accessibilityTrusted else {
            headline = "Enable Accessibility"
            subheadline = "\(ContextAssemblyBrand.appName) needs Accessibility to capture from \(targetApp.localizedName ?? "that app")."
            statusTone = .warning
            presentToast(
                PackToastState(
                    kind: .error,
                    title: "Need Accessibility",
                    detail: "Capture needs Accessibility. Use the Permissions button if you want \(ContextAssemblyBrand.appName) to ask macOS again.",
                    preview: "If \(ContextAssemblyBrand.appName) is already enabled, quit and reopen it, then try \(ClipboardStudioShortcut.captureSelection.keyChord) again.",
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
                actionDetail: result.captureMethodDescription,
                captureDate: Date(),
                autoStartAssembly: autoStartAssembly
            )
            refreshCurrentFocus(
                force: true,
                preferredSelection: result.text,
                recordInHistory: true
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
            headline = "Assembly Empty"
            subheadline = "Capture a few clips before sending the assembly."
            statusTone = .warning
            return
        }

        setClipboardText(formattedPack)

        guard let targetApp = currentTargetApplication() else {
            applyClipboardFallback(
                targetAppName: nil,
                detail: "Copied the assembly to the clipboard because there was no frontmost destination app."
            )
            return
        }

        accessibilityTrusted = ClipboardAutomationService.isTrusted()
        guard accessibilityTrusted else {
            applyClipboardFallback(
                targetAppName: targetApp.localizedName,
                detail: "Copied the assembly to the clipboard because direct send needs Accessibility permission. Use Permissions if you want macOS to prompt again."
            )
            return
        }

        headline = "Pasting..."
        subheadline = "Sending the assembly into \(targetApp.localizedName ?? "your app")."
        statusTone = .working

        do {
            try await ClipboardAutomationService.pasteClipboardContents(into: targetApp)
            lastSendResult = LastSendResult(
                delivery: .directSend,
                targetAppName: targetApp.localizedName,
                detail: "Delivered the assembly directly into \(targetApp.localizedName ?? "the target app").",
                timestamp: Date()
            )
            headline = "Assembly Sent"
            subheadline = "Delivered the assembly directly into \(targetApp.localizedName ?? "the target app")."
            statusTone = .success
            presentToast(
                PackToastState(
                    kind: .directSend,
                    title: "Assembly Sent",
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
                detail: "Copied the assembly to the clipboard because direct send failed: \(error.localizedDescription)"
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
        actionDetail: String,
        captureDate: Date,
        autoStartAssembly: Bool
    ) {
        guard let normalized = normalizedText(from: text) else {
            headline = "Empty Selection"
            subheadline = "There was no usable text in the current selection."
            statusTone = .warning
            return
        }

        let entry = historyStore.record(
            text: normalized,
            sourceAppName: sourceAppName,
            limit: Limits.historyCount,
            createdAt: captureDate
        )
        persistHistoryState()

        guard destination == .pack else {
            headline = "Selection Captured"
            subheadline = "\(actionDetail) from \(entry.sourceLabel) and saved it to history."
            statusTone = .success
            presentToast(
                PackToastState(
                    kind: .capture,
                    title: "Saved To History",
                    detail: "\(actionDetail) from \(entry.sourceLabel).",
                    preview: previewLine(for: normalized),
                    sourceAppName: sourceAppName,
                    packCount: contextPack.count,
                    undoItemID: nil,
                    autoDismissAfter: 2.6
                )
            )
            return
        }

        let assemblyWasEmpty = contextPack.isEmpty

        switch contextPack.insert(text: entry.text, sourceAppName: sourceAppName, capturedAt: captureDate) {
        case let .added(item):
            lastUndoablePackItemID = item.id
            if autoStartAssembly && assemblyWasEmpty {
                headline = "Assembly Started"
                subheadline = "Captured the first step from \(item.sourceLabel). The assembly window is open for the next context."
                openPackEditor()
            } else {
                headline = "Selection Added"
                subheadline = "\(actionDetail) from \(item.sourceLabel) and added it to the active assembly."
            }
            statusTone = .success
            persistPackState()
            presentToast(
                PackToastState(
                    kind: .capture,
                    title: "Added To Assembly",
                    detail: assemblyWasEmpty && autoStartAssembly
                        ? "Started from \(item.sourceLabel). Keep capturing and the timeline will build."
                        : "Captured from \(item.sourceLabel) and ready for \(ClipboardStudioShortcut.sendPack.keyChord).",
                    preview: item.previewLine,
                    sourceAppName: item.sourceAppName,
                    packCount: contextPack.count,
                    undoItemID: item.id,
                    autoDismissAfter: 3.2
                )
            )
        case let .duplicate(existing):
            headline = "Already In Assembly"
            subheadline = "That exact selection was already captured, so the assembly stayed clean."
            statusTone = .warning
            presentToast(
                PackToastState(
                    kind: .duplicate,
                    title: "Already In Assembly",
                    detail: "Skipped a duplicate capture from \(existing.sourceLabel).",
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

    private func currentSelectionText() -> String? {
        guard let selectedText = currentFocusSnapshot?.selectedText else { return nil }
        return normalizedText(from: selectedText)
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
        _ = historyStore.record(
            text: normalized,
            sourceAppName: sourceAppName,
            limit: Limits.historyCount
        )
        persistHistoryState()
        refreshCurrentFocus(
            force: true,
            preferredSelection: normalized,
            recordInHistory: true
        )
    }

    private func beginMonitoringCurrentFocus() {
        focusPollTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshCurrentFocus(recordInHistory: true)
            }
        }
        if let focusPollTimer {
            RunLoop.main.add(focusPollTimer, forMode: .common)
        }
    }

    private func refreshCurrentFocus(
        force: Bool = false,
        preferredSelection: String? = nil,
        recordInHistory: Bool
    ) {
        guard let targetApp = currentTargetApplication() else { return }

        let snapshot = CurrentContextSnapshotService.captureSnapshot(
            from: targetApp,
            preferredSelection: preferredSelection
        )

        let signatureChanged = snapshot.signature != currentFocusSnapshot?.signature
        guard force || signatureChanged || currentFocusSnapshot == nil else { return }

        currentFocusSnapshot = snapshot
        persistCurrentFocusState()

        if recordInHistory {
            let stored = focusHistoryStore.record(snapshot: snapshot, limit: Limits.focusHistoryCount)
            if stored != snapshot {
                currentFocusSnapshot = stored
                persistCurrentFocusState()
            }
            persistFocusHistoryState()
        }
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
                self?.refreshCurrentFocus(force: true, recordInHistory: true)
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
        if defaults.object(forKey: DefaultsKey.keepAssemblyWindowVisible) == nil {
            keepsAssemblyWindowVisible = true
        } else {
            keepsAssemblyWindowVisible = defaults.bool(forKey: DefaultsKey.keepAssemblyWindowVisible)
        }
        isPrivateMode = defaults.bool(forKey: DefaultsKey.privateMode)
        packObjective = defaults.string(forKey: DefaultsKey.packObjective) ?? ""
        if let storedPath = defaults.string(forKey: DefaultsKey.markdownExportFolderPath),
           FileManager.default.fileExists(atPath: storedPath) {
            markdownExportFolderPath = storedPath
        }

        if let data = defaults.data(forKey: DefaultsKey.historyStore),
           let decoded = try? decoder.decode(ClipboardHistoryStore.self, from: data) {
            historyStore = decoded
        }

        if let data = defaults.data(forKey: DefaultsKey.focusHistoryStore),
           let decoded = try? decoder.decode(FocusHistoryStore.self, from: data) {
            focusHistoryStore = decoded
        }

        if let data = defaults.data(forKey: DefaultsKey.currentFocusSnapshot),
           let decoded = try? decoder.decode(FocusSnapshot.self, from: data) {
            currentFocusSnapshot = decoded
        }

        if let data = defaults.data(forKey: DefaultsKey.contextPack),
           let decoded = try? decoder.decode(ContextPack.self, from: data) {
            contextPack = decoded
        }

        if !contextPack.isEmpty {
            headline = "Assembly Restored"
            subheadline = "\(contextPack.count) saved capture\(contextPack.count == 1 ? "" : "s") came back after relaunch."
            statusTone = .ready
        } else if let currentFocusSnapshot {
            headline = "State Restored"
            subheadline = "Picked up from \(currentFocusSnapshot.sourceLabel) where you left off."
            statusTone = .ready
        }
    }

    private func persistHistoryState() {
        if let data = try? encoder.encode(historyStore) {
            defaults.set(data, forKey: DefaultsKey.historyStore)
        }
    }

    private func persistFocusHistoryState() {
        if let data = try? encoder.encode(focusHistoryStore) {
            defaults.set(data, forKey: DefaultsKey.focusHistoryStore)
        }
    }

    private func persistCurrentFocusState() {
        if let currentFocusSnapshot,
           let data = try? encoder.encode(currentFocusSnapshot) {
            defaults.set(data, forKey: DefaultsKey.currentFocusSnapshot)
        } else {
            defaults.removeObject(forKey: DefaultsKey.currentFocusSnapshot)
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

    private func currentAssemblyExportPayload(referenceDate: Date = Date()) -> (title: String, document: String)? {
        guard !contextPack.isEmpty else {
            headline = "Assembly Empty"
            subheadline = "Capture a few clips before exporting the assembly."
            statusTone = .warning
            return nil
        }

        let title = ContextAssemblyExportService.suggestedTitle(
            objective: packObjective,
            pack: contextPack,
            exportedAt: referenceDate
        )
        let document = ContextPackFormatter.formatExportDocument(
            title: title,
            objective: packObjective,
            pack: contextPack,
            exportedAt: referenceDate
        )
        return (title, document)
    }

    private func resolvedMarkdownExportFolderURL(promptIfNeeded: Bool) -> URL? {
        if let markdownExportFolderPath {
            let storedURL = URL(fileURLWithPath: markdownExportFolderPath, isDirectory: true)
            if FileManager.default.fileExists(atPath: storedURL.path) {
                return storedURL
            }
            storeMarkdownExportFolder(nil)
        }

        guard promptIfNeeded, let selectedURL = promptForMarkdownExportFolder() else {
            return nil
        }

        storeMarkdownExportFolder(selectedURL)
        return selectedURL
    }

    private func promptForMarkdownExportFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Folder"
        panel.message = "Choose where Context Assembly should save Markdown exports."
        if let markdownExportFolderPath {
            panel.directoryURL = URL(fileURLWithPath: markdownExportFolderPath, isDirectory: true)
        }
        guard panel.runModal() == .OK else { return nil }
        return panel.urls.first
    }

    private func storeMarkdownExportFolder(_ url: URL?) {
        markdownExportFolderPath = url?.path
        defaults.set(url?.path, forKey: DefaultsKey.markdownExportFolderPath)
    }

    private func refreshOpenAIKeyStatus() {
        hasStoredOpenAIKey = !((try? keychain.read(account: Secrets.openAIKey)) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    private func previewLine(for text: String) -> String {
        let firstLine = text
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !firstLine.isEmpty else { return "Assembly ready" }
        return String(firstLine.prefix(96))
    }

    private func applyClipboardFallback(targetAppName: String?, detail: String) {
        lastSendResult = LastSendResult(
            delivery: .clipboardFallback,
            targetAppName: targetAppName,
            detail: detail,
            timestamp: Date()
        )
        headline = "Assembly Copied Instead"
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

        if !contextPack.isEmpty {
            headline = "Assembly Ready"
            subheadline = "\(contextPack.count) saved capture\(contextPack.count == 1 ? "" : "s") ready for \(ClipboardStudioShortcut.sendPack.keyChord)."
            statusTone = .ready
            return
        }

        if let currentFocusSnapshot {
            headline = "State Ready"
            subheadline = "Current focus from \(currentFocusSnapshot.sourceLabel) is saved and ready to use."
            statusTone = .ready
        }
    }
}
