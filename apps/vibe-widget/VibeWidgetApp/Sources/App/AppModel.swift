import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WidgetKit
import VibeWidgetCore

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var widgetSnapshot: WidgetSnapshot
    @Published var contextLibrary: ContextLibrarySnapshot
    @Published var homes: [HomeSummary] = []
    @Published var discoveryLanes: [DiscoveryLane] = []
    @Published var scoutBrief = DiscoveryScoutBrief.placeholder
    @Published var recommendations: [VibeRecommendation]
    @Published var permissionSnapshot = PermissionSnapshot()
    @Published var commandText = ""
    @Published var parsedPlan: AICommandPlan?
    @Published var activePanelRoute: WorkspacePanelRoute = .vibe
    @Published var contextSearchText = ""
    @Published var contextMatches: [ContextSearchMatch] = []
    @Published var isProcessing = false
    @Published var isPanelPresented = false
    @Published var isListening = false
    @Published var isIndexingContext = false
    @Published var isRefreshingDiscovery = false
    @Published var documentPrepReport: DocumentPrepReport?
    @Published var isPreparingDocument = false
    @Published var contextStatusMessage = "Drop files to build a local context pack."
    @Published var statusMessage = "Scout is on standby for the next obsession."
    @Published var documentPrepStatusMessage = "Drop a Word doc to create sections, chunks, key points, and JSONL export."
    @Published var paperBridgePrompt = ""
    @Published var paperBridgeTokenInput = ""
    @Published var paperBridgeRecentRuns: [PaperBridgeRun] = []
    @Published var paperBridgeStatusMessage = "Save a GitHub token and connect a repo to start."
    @Published var isDispatchingPaperBridge = false
    @Published var isRefreshingPaperBridge = false
    @Published var hasSavedGitHubToken = false

    let store: SharedStore

    private let homeService = HomeService()
    private let spotifyService = SpotifyService()
    private let aiCommandService = AICommandService()
    private let permissionService = PermissionService()
    private let speechCapture = SpeechCaptureService()
    private let audioRouteService = AudioRouteService()
    private let contextIngestionService = ContextIngestionService()
    private let documentPreparationService = DocumentPreparationService()
    private let paperBridgeService = PaperBridgeService()

    private var hasBootstrapped = false
    private var lastDiscoverySeedKey: String?

    init(store: SharedStore = .shared) {
        self.store = store
        let loadedSettings = store.loadSettings()
        var loadedSnapshot = store.loadSnapshot()
        let loadedContextLibrary = store.loadContextLibrary()

        if loadedSnapshot.topRecommendation?.spotifyURI == nil {
            loadedSnapshot.topRecommendation = nil
        }

        settings = loadedSettings
        widgetSnapshot = loadedSnapshot
        contextLibrary = loadedContextLibrary
        scoutBrief = DiscoveryScoutBrief(
            mood: loadedSnapshot.nowPlaying.isPlaying ? "Already in motion" : DiscoveryScoutBrief.placeholder.mood,
            summary: loadedSnapshot.lastActionResult.isEmpty ? DiscoveryScoutBrief.placeholder.summary : loadedSnapshot.lastActionResult,
            quip: loadedSnapshot.nowPlaying.isPlaying ? "Tasteful. Inconveniently tasteful." : DiscoveryScoutBrief.placeholder.quip
        )
        recommendations = loadedSnapshot.topRecommendation.map { [$0] } ?? []
        statusMessage = loadedSnapshot.lastActionResult.isEmpty
            ? "Scout is on standby for the next obsession."
            : loadedSnapshot.lastActionResult
        contextStatusMessage = loadedContextLibrary.documents.isEmpty
            ? "Drop files to build a local context pack."
            : "Context pack ready with \(loadedContextLibrary.documents.count) files."
        hasSavedGitHubToken = paperBridgeService.hasSavedGitHubToken(serviceName: loadedSettings.githubTokenServiceName)
        paperBridgeStatusMessage = initialPaperBridgeStatusMessage(for: loadedSettings)
        normalizeMindDeclutterSessionIfNeeded(silently: true)
    }

    var topRecommendation: VibeRecommendation? {
        discoveryLanes.first?.recommendation ?? widgetSnapshot.topRecommendation ?? recommendations.first
    }

    var primaryDiscoveryLane: DiscoveryLane? {
        discoveryLanes.first
    }

    var latestPaperBridgeRun: PaperBridgeRun? {
        paperBridgeRecentRuns.first
    }

    var latestPaperBridgeArtifact: PaperBridgeArtifact? {
        if let preferred = latestPaperBridgeRun?.artifacts.first(where: {
            $0.name == settings.paperArtifactName && !$0.expired
        }) {
            return preferred
        }

        return latestPaperBridgeRun?.artifacts.first(where: { !$0.expired })
    }

    var paperBridgeRunLabel: String {
        guard let run = latestPaperBridgeRun else {
            return settings.hasPaperBridgeConfiguration ? "Ready to dispatch" : "Setup needed"
        }

        return "Run #\(run.runNumber) • \(run.stateLabel)"
    }

    var paperBridgeStatusDetail: String {
        if let artifact = latestPaperBridgeArtifact {
            return "\(paperBridgeRunLabel) • \(artifact.sizeLabel)"
        }

        if let run = latestPaperBridgeRun {
            return "\(paperBridgeRunLabel) • \(run.updatedAt.formatted(date: .abbreviated, time: .shortened))"
        }

        return paperBridgeStatusMessage
    }

    var paperBridgeShortSummary: String {
        if isDispatchingPaperBridge {
            return "Dispatching"
        }

        if isRefreshingPaperBridge {
            return "Checking latest run"
        }

        if let run = latestPaperBridgeRun {
            return run.stateLabel
        }

        return settings.hasPaperBridgeConfiguration ? "Ready" : "Setup"
    }

    var mindDeclutterPlan: MindDeclutterPlan {
        MindDeclutterPlan(
            inboxText: settings.mindDeclutterInboxText,
            focusText: settings.mindDeclutterFocusText
        )
    }

    var hasMindDeclutterDraft: Bool {
        !settings.mindDeclutterInboxText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var mindDeclutterSessionMinutes: Int {
        normalizedMindDeclutterSessionMinutes(settings.mindDeclutterSessionMinutes)
    }

    func isMindDeclutterActive(at date: Date = .now) -> Bool {
        guard settings.mindDeclutterEnabled else { return false }
        guard let endsAt = settings.mindDeclutterSessionEndsAt else { return true }
        return endsAt > date
    }

    var isMindDeclutterActive: Bool {
        isMindDeclutterActive(at: .now)
    }

    var mindDeclutterFocusTask: String? {
        mindDeclutterPlan.focusTask
    }

    var mindDeclutterBlockers: [String] {
        mindDeclutterPlan.blockers
    }

    var mindDeclutterBlockerCount: Int {
        mindDeclutterPlan.blockerCount
    }

    var mindDeclutterParkingLot: [String] {
        mindDeclutterPlan.parkingLot
    }

    var mindDeclutterParkingCount: Int {
        mindDeclutterPlan.parkingCount
    }

    var mindDeclutterOverflowCount: Int {
        mindDeclutterPlan.overflowCount
    }

    var mindDeclutterActionableCount: Int {
        mindDeclutterPlan.actionableCount
    }

    func mindDeclutterToolbarSymbolName(at date: Date = .now) -> String {
        isMindDeclutterActive(at: date) ? "bell.slash.fill" : "bell.slash"
    }

    var mindDeclutterToolbarSymbolName: String {
        mindDeclutterToolbarSymbolName()
    }

    func mindDeclutterStatusLine(at date: Date = .now) -> String {
        if isMindDeclutterActive(at: date), let focusTask = mindDeclutterFocusTask {
            return "\(mindDeclutterSessionLabel(at: date)) • Focus now: \(focusTask)"
        }

        if isMindDeclutterActive(at: date) {
            return "\(mindDeclutterSessionLabel(at: date)) • Empty the noisy tabs in your head and keep one next move."
        }

        if let focusTask = mindDeclutterFocusTask {
            return "Next move ready: \(focusTask)"
        }

        return "Dump the noisy tabs in your head, keep one next step, and park the rest."
    }

    var mindDeclutterStatusLine: String {
        mindDeclutterStatusLine()
    }

    func mindDeclutterPanelSubtitle(at date: Date = .now) -> String {
        let blockerCount = mindDeclutterBlockerCount
        let parkedCount = mindDeclutterParkingCount

        if isMindDeclutterActive(at: date) {
            if blockerCount > 0 {
                return "Hold one next step, park the rest, and keep \(blockerCount) blocker\(blockerCount == 1 ? "" : "s") visible."
            }
            return "One clean next step right now. Everything else belongs in the parking lot."
        }

        if hasMindDeclutterDraft {
            if blockerCount > 0 || parkedCount > 0 {
                return "\(blockedAndParkedSummary(blockers: blockerCount, parked: parkedCount)). Start a short quiet block when you are ready."
            }
            return "Your dump is staged. Start a short quiet block when you are ready."
        }

        return "Offload the work noise, shrink it to one move, and park the rest."
    }

    var mindDeclutterPanelSubtitle: String {
        mindDeclutterPanelSubtitle()
    }

    func mindDeclutterHelperText(at date: Date = .now) -> String {
        if isMindDeclutterActive(at: date), let focusTask = mindDeclutterFocusTask {
            return "Stay with one move: \(focusTask)"
        }

        if !mindDeclutterBlockers.isEmpty {
            return "Blockers stay visible on purpose. If one is the real constraint, pin it as the focus task and define the unblock step."
        }

        if settings.mindDeclutterFocusText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let suggestion = mindDeclutterPlan.suggestedFocusTask {
            return "Use Suggestion will pin \(suggestion) as the one next move."
        }

        return "Use one line per loose task. Prefix a line with now:, later:, or blocker: if you want more control."
    }

    var mindDeclutterHelperText: String {
        mindDeclutterHelperText()
    }

    func menuBarHelpText(at date: Date = .now) -> String {
        if isMindDeclutterActive(at: date) || hasMindDeclutterDraft {
            return mindDeclutterStatusLine(at: date)
        }

        return "VibeWidget"
    }

    var menuBarHelpText: String {
        menuBarHelpText()
    }

    var scoutRouteLine: String {
        switch widgetSnapshot.routeStatus.availability {
        case .connected:
            return "\(widgetSnapshot.routeStatus.preferredOutput) is locked in and behaving."
        case .available:
            return "\(widgetSnapshot.routeStatus.preferredOutput) is nearby and still being a little dramatic."
        case .missing:
            return "\(widgetSnapshot.routeStatus.preferredOutput) is playing hide-and-seek again."
        }
    }

    var contextDocuments: [ContextDocumentRecord] {
        contextLibrary.documents.sorted {
            if $0.importedAt == $1.importedAt {
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            return $0.importedAt > $1.importedAt
        }
    }

    var contextTokenSummary: String {
        let totalTokens = contextLibrary.totalEstimatedTokens
        if totalTokens >= 1_000 {
            return String(format: "%.1fk", Double(totalTokens) / 1_000)
        }
        return "\(totalTokens)"
    }

    func bootstrap() async {
        if hasBootstrapped {
            await refresh()
            await processPendingWidgetActions()
            return
        }
        hasBootstrapped = true
        await refresh()
        await processPendingWidgetActions()
    }

    func refresh() async {
        normalizeMindDeclutterSessionIfNeeded()
        hasSavedGitHubToken = paperBridgeService.hasSavedGitHubToken(serviceName: settings.githubTokenServiceName)
        homes = await homeService.fetchHomes()
        if settings.selectedHomeID == nil, let firstHome = homes.first {
            settings.selectedHomeID = firstHome.id
            settings.selectedHomeName = firstHome.name
            persistSettings()
        }

        permissionSnapshot = await permissionService.refresh(homeAvailable: !homes.isEmpty)
        widgetSnapshot.routeStatus = audioRouteService.currentStatus(preferredOutput: settings.preferredSpeakerName)
        widgetSnapshot.nowPlaying = await spotifyService.currentNowPlaying()
        await refreshDiscovery(for: widgetSnapshot.nowPlaying, force: shouldRefreshDiscovery(for: widgetSnapshot.nowPlaying))

        if widgetSnapshot.lastActionResult.isEmpty {
            widgetSnapshot.lastActionResult = "Scout is on standby for the next obsession."
        }

        await refreshPaperBridgeStatus()
        persistSnapshot()
    }

    func persistSettings() {
        store.saveSettings(settings)
        hasSavedGitHubToken = paperBridgeService.hasSavedGitHubToken(serviceName: settings.githubTokenServiceName)
    }

    func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active else { return }
        Task {
            await refresh()
            await processPendingWidgetActions()
        }
    }

    func handleIncomingURL(_ url: URL) {
        Task {
            if url.absoluteString.contains("spotify-callback") {
                do {
                    statusMessage = try await spotifyService.handleCallback(url, clientID: settings.spotifyClientID)
                    await refresh()
                } catch {
                    statusMessage = "Spotify login flinched at the last second."
                }
            } else {
                presentPanel(route: .vibe)
            }
        }
    }

    func requestSetupPermissions() {
        Task {
            permissionSnapshot.microphone = await permissionService.requestMicrophone()
            permissionSnapshot.speech = await permissionService.requestSpeech()
            homes = await homeService.fetchHomes()
            permissionSnapshot.home = homes.isEmpty ? .unknown : .granted
        }
    }

    func beginSpotifyLogin() {
        do {
            let url = try spotifyService.authorizationURL(clientID: settings.spotifyClientID)
            NSWorkspace.shared.open(url)
            statusMessage = "Spotify sign-in opened. Scout sent the paperwork."
        } catch {
            statusMessage = "Add a Spotify client ID before connecting."
        }
    }

    func updateMindDeclutterInbox(_ text: String) {
        settings.mindDeclutterInboxText = text
        persistSettings()
    }

    func updateMindDeclutterFocus(_ text: String) {
        settings.mindDeclutterFocusText = text
        persistSettings()
    }

    func setMindDeclutterSessionMinutes(_ minutes: Int) {
        let normalizedMinutes = normalizedMindDeclutterSessionMinutes(minutes)
        guard settings.mindDeclutterSessionMinutes != normalizedMinutes else { return }
        settings.mindDeclutterSessionMinutes = normalizedMinutes
        persistSettings()
    }

    func useSuggestedMindDeclutterFocus() {
        guard let suggestion = mindDeclutterPlan.suggestedFocusTask else {
            statusMessage = "Drop a few loose tasks first so I have something to pin."
            return
        }

        settings.mindDeclutterFocusText = suggestion
        persistSettings()
        statusMessage = "Pinned one clean next step."
    }

    func toggleMindDeclutterSession() {
        normalizeMindDeclutterSessionIfNeeded(silently: true)

        if isMindDeclutterActive {
            endMindDeclutterSession()
        } else {
            startMindDeclutterSession()
        }
    }

    func startMindDeclutterSession(minutes: Int? = nil) {
        let durationMinutes = normalizedMindDeclutterSessionMinutes(minutes ?? settings.mindDeclutterSessionMinutes)
        settings.mindDeclutterSessionMinutes = durationMinutes
        settings.mindDeclutterEnabled = true
        settings.mindDeclutterSessionEndsAt = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))

        if settings.mindDeclutterFocusText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let suggestion = mindDeclutterPlan.suggestedFocusTask {
            settings.mindDeclutterFocusText = suggestion
        }

        persistSettings()

        if let focusTask = mindDeclutterFocusTask {
            statusMessage = "Mind declutter is on for \(durationMinutes)m. Focus now: \(focusTask)"
        } else {
            statusMessage = "Mind declutter is on for \(durationMinutes)m. Dump the loose tabs and I will narrow the next step."
        }
    }

    func endMindDeclutterSession() {
        settings.mindDeclutterEnabled = false
        settings.mindDeclutterSessionEndsAt = nil
        persistSettings()
        statusMessage = hasMindDeclutterDraft
            ? "Mind declutter is off. Your parked tasks stayed put."
            : "Mind declutter is off."
    }

    func clearMindDeclutterCapture() {
        settings.mindDeclutterInboxText = ""
        settings.mindDeclutterFocusText = ""
        settings.mindDeclutterEnabled = false
        settings.mindDeclutterSessionEndsAt = nil
        persistSettings()
        statusMessage = "Cleared the mental inbox."
    }

    func copyMindDeclutterFocus() {
        guard let focusTask = mindDeclutterFocusTask else {
            statusMessage = "Add a few loose tasks first so I have a next step to copy."
            return
        }

        copyToPasteboard(focusTask)
        statusMessage = "Copied the next step to the clipboard."
    }

    func copyMindDeclutterBrief() {
        let plan = mindDeclutterPlan
        guard plan.hasCapture || plan.focusTask != nil else {
            statusMessage = "Add a few loose tasks first so I have something to summarize."
            return
        }

        var sections = [String]()

        if let focusTask = plan.focusTask {
            sections.append("Focus now")
            sections.append("- \(focusTask)")
        }

        if !plan.blockers.isEmpty {
            if !sections.isEmpty {
                sections.append("")
            }
            sections.append("Blockers")
            sections.append(contentsOf: plan.blockers.map { "- \($0)" })
        }

        if !plan.parkingLot.isEmpty {
            if !sections.isEmpty {
                sections.append("")
            }
            sections.append("Park later")
            sections.append(contentsOf: plan.parkingLot.map { "- \($0)" })
            if plan.overflowCount > 0 {
                sections.append("- ...and \(plan.overflowCount) more parked item\(plan.overflowCount == 1 ? "" : "s")")
            }
        }

        copyToPasteboard(sections.joined(separator: "\n"))
        statusMessage = "Copied the declutter brief."
    }

    func mindDeclutterSessionLabel(at date: Date = .now) -> String {
        guard settings.mindDeclutterEnabled else {
            return hasMindDeclutterDraft ? "Draft ready" : "Idle"
        }

        guard let endsAt = settings.mindDeclutterSessionEndsAt else {
            return "On"
        }

        let remainingInterval = endsAt.timeIntervalSince(date)
        guard remainingInterval > 0 else {
            return "Session done"
        }

        let remainingMinutes = max(1, Int(ceil(remainingInterval / 60)))
        return remainingMinutes == 1 ? "1 min left" : "\(remainingMinutes) min left"
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        if let selected = homes.first(where: { $0.name == settings.selectedHomeName }) ?? homes.first {
            settings.selectedHomeID = selected.id
            settings.selectedHomeName = selected.name
        }
        persistSettings()
        Task {
            await refresh()
            presentPanel(route: .vibe)
        }
    }

    func performQuickAction(_ kind: WidgetActionKind) {
        Task {
            await run(action: QueuedWidgetAction(kind: kind))
        }
    }

    func playDiscoveryLane(_ lane: DiscoveryLane) {
        Task {
            let playbackOutcome = await spotifyService.playRecommendation(lane.recommendation)
            widgetSnapshot.topRecommendation = lane.recommendation
            switch playbackOutcome {
            case .played:
                widgetSnapshot.lastActionResult = "Playing \(lane.recommendation.title) from the \(lane.kind.title.lowercased()) lane."
            case .revealed:
                widgetSnapshot.lastActionResult = "Opened the exact \(lane.recommendation.title) track in Spotify. Playback got theatrical."
            case .unresolved:
                widgetSnapshot.lastActionResult = "Scout refused to fake the \(lane.kind.title.lowercased()) lane without one exact Spotify track."
            }
            widgetSnapshot.updatedAt = .now
            statusMessage = widgetSnapshot.lastActionResult
            widgetSnapshot.nowPlaying = await spotifyService.currentNowPlaying()
            await refreshDiscovery(for: widgetSnapshot.nowPlaying, force: true)
            persistSnapshot()
        }
    }

    func openCurrentTrack() {
        spotifyService.openCurrentTrack(from: widgetSnapshot.nowPlaying)
    }

    func processPendingWidgetActions() async {
        let actions = store.dequeueAllActions()
        for action in actions {
            await run(action: action)
        }
    }

    func runCommand() async {
        let trimmed = commandText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isProcessing = true
        let plan = await aiCommandService.plan(for: trimmed, settings: settings)
        parsedPlan = plan

        if plan.needsConfirmation || plan.confidence < 0.66 {
            statusMessage = "Check the parsed vibe before I run it."
            presentPanel(route: .vibe)
            isProcessing = false
            return
        }

        await execute(plan: plan)
        isProcessing = false
    }

    func confirmParsedPlan() {
        guard let parsedPlan else { return }
        Task {
            isProcessing = true
            await execute(plan: parsedPlan)
            self.parsedPlan = nil
            isProcessing = false
        }
    }

    func toggleVoiceCapture() {
        Task {
            if speechCapture.isRecording {
                speechCapture.stop()
                isListening = false
                if !commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await runCommand()
                }
                return
            }

            permissionSnapshot.microphone = await permissionService.requestMicrophone()
            permissionSnapshot.speech = await permissionService.requestSpeech()

            guard permissionSnapshot.microphone == .granted, permissionSnapshot.speech == .granted else {
                statusMessage = "Mic and speech access are both needed for voice control."
                return
            }

            do {
                try speechCapture.start { [weak self] partial in
                    Task { @MainActor in
                        self?.commandText = partial
                    }
                } onFinish: { [weak self] finalText in
                    Task { @MainActor in
                        guard let self else { return }
                        self.commandText = finalText
                        self.isListening = false
                        await self.runCommand()
                    }
                }
                isListening = true
                statusMessage = "Listening now. Try to be interesting."
            } catch {
                statusMessage = "Voice capture could not start."
            }
        }
    }

    func openSoundSettings() {
        audioRouteService.openSoundSettings()
    }

    func openBluetoothSettings() {
        audioRouteService.openBluetoothSettings()
    }

    func savePaperBridgeGitHubToken() {
        let trimmedToken = paperBridgeTokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            paperBridgeStatusMessage = "Paste a GitHub token first."
            return
        }

        do {
            try paperBridgeService.saveGitHubToken(trimmedToken, serviceName: settings.githubTokenServiceName)
            paperBridgeTokenInput = ""
            hasSavedGitHubToken = true
            paperBridgeStatusMessage = "GitHub token saved to Keychain."
        } catch {
            paperBridgeStatusMessage = "Could not save the GitHub token."
        }
    }

    func runPaperBridgePrompt() {
        let trimmedPrompt = paperBridgePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            paperBridgeStatusMessage = "Add a prompt before dispatching."
            return
        }

        persistSettings()

        Task {
            isDispatchingPaperBridge = true
            paperBridgeStatusMessage = "Dispatching the GitHub workflow…"

            do {
                let run = try await paperBridgeService.dispatchPrompt(prompt: trimmedPrompt, settings: settings)
                paperBridgePrompt = ""
                if let run {
                    mergePaperBridgeRun(run)
                    settings.paperLastRunID = run.id
                    paperBridgeStatusMessage = paperBridgeMessage(for: run)
                    persistSettings()
                } else {
                    paperBridgeStatusMessage = "Workflow dispatched. Refresh in a moment for the run details."
                }
            } catch {
                paperBridgeStatusMessage = error.localizedDescription
            }

            isDispatchingPaperBridge = false
        }
    }

    func refreshPaperBridgeStatus() async {
        guard settings.hasPaperBridgeConfiguration else {
            paperBridgeRecentRuns = []
            paperBridgeStatusMessage = initialPaperBridgeStatusMessage(for: settings)
            return
        }

        guard hasSavedGitHubToken else {
            paperBridgeRecentRuns = []
            paperBridgeStatusMessage = "Save a GitHub token for \(settings.paperRepositorySlug) to fetch runs."
            return
        }

        isRefreshingPaperBridge = true

        do {
            let snapshot = try await paperBridgeService.fetchWorkflowSnapshot(settings: settings)
            paperBridgeRecentRuns = snapshot.recentRuns

            if let latestRun = snapshot.latestRun {
                settings.paperLastRunID = latestRun.id
                paperBridgeStatusMessage = paperBridgeMessage(for: latestRun)
                persistSettings()
            } else {
                paperBridgeStatusMessage = "Paper Bridge is configured. Dispatch a prompt to create the first run."
            }
        } catch {
            paperBridgeStatusMessage = error.localizedDescription
        }

        isRefreshingPaperBridge = false
    }

    func openPaperBridgeActions() {
        guard let url = URL(string: "https://github.com/\(settings.paperRepositorySlug)/actions") else { return }
        NSWorkspace.shared.open(url)
    }

    func openPaperBridgeSecrets() {
        guard let url = URL(string: "https://github.com/\(settings.paperRepositorySlug)/settings/secrets/actions") else { return }
        NSWorkspace.shared.open(url)
    }

    func openPaperBridgeLatestRun() {
        guard let url = latestPaperBridgeRun?.htmlURL else { return }
        NSWorkspace.shared.open(url)
    }

    func openPaperBridgeOverleafProject() {
        let projectID = settings.paperOverleafProjectID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !projectID.isEmpty else {
            paperBridgeStatusMessage = "Add the Overleaf project ID to open the project."
            return
        }

        guard let url = URL(string: "https://www.overleaf.com/project/\(projectID)") else { return }
        NSWorkspace.shared.open(url)
    }

    func downloadPaperBridgeArtifact() {
        guard let artifact = latestPaperBridgeArtifact else {
            paperBridgeStatusMessage = "No artifact is ready yet. Wait for the latest run to finish."
            return
        }

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = artifact.downloadFilename
        savePanel.allowedContentTypes = [.zip]
        savePanel.canCreateDirectories = true
        savePanel.title = "Save Latest Paper Artifact"

        guard savePanel.runModal() == .OK, let destinationURL = savePanel.url else { return }

        Task {
            do {
                try await paperBridgeService.downloadArtifact(
                    artifact,
                    settings: settings,
                    destinationURL: destinationURL
                )
                paperBridgeStatusMessage = "Saved \(destinationURL.lastPathComponent)."
                NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
            } catch {
                paperBridgeStatusMessage = error.localizedDescription
            }
        }
    }

    func copyPaperBridgeWorkflowTemplate() {
        copyToPasteboard(paperBridgeService.workflowTemplate(settings: settings))
        paperBridgeStatusMessage = "Copied the GitHub Actions workflow template."
    }

    func copyPaperBridgePromptScriptTemplate() {
        copyToPasteboard(paperBridgeService.promptScriptTemplate(settings: settings))
        paperBridgeStatusMessage = "Copied the sample prompt-to-LaTeX script."
    }

    func copyPaperBridgeSecretsChecklist() {
        copyToPasteboard(paperBridgeService.secretsChecklist(settings: settings))
        paperBridgeStatusMessage = "Copied the GitHub secrets checklist."
    }

    func presentPanel(route: WorkspacePanelRoute = .vibe) {
        activePanelRoute = route
        isPanelPresented = true
    }

    func ingestContextFiles(_ urls: [URL]) {
        let uniqueURLs = Dictionary(grouping: urls.map(\.standardizedFileURL), by: \.path).compactMap { $0.value.first }
        guard !uniqueURLs.isEmpty else { return }

        Task {
            isIndexingContext = true
            activePanelRoute = .context
            contextStatusMessage = uniqueURLs.count == 1
                ? "Indexing \(uniqueURLs[0].lastPathComponent)…"
                : "Indexing \(uniqueURLs.count) dropped items…"

            let report = await contextIngestionService.ingest(urls: uniqueURLs, into: contextLibrary)
            contextLibrary = report.library
            persistContextLibrary()
            await refreshContextMatches()
            isIndexingContext = false
            contextStatusMessage = contextStatusMessage(for: report)
        }
    }

    func refreshContextMatches() async {
        let trimmedQuery = contextSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            contextMatches = []
            return
        }

        contextMatches = await contextIngestionService.search(query: trimmedQuery, in: contextLibrary)
    }

    func removeContextDocument(_ document: ContextDocumentRecord) {
        contextLibrary.documents.removeAll { $0.id == document.id }
        persistContextLibrary()
        contextStatusMessage = contextLibrary.documents.isEmpty
            ? "Context pack cleared."
            : "Removed \(document.title)."

        Task {
            await contextIngestionService.removeStoredContent(for: [document])
            await refreshContextMatches()
        }
    }

    func clearContextLibrary() {
        let documents = contextLibrary.documents
        contextLibrary = ContextLibrarySnapshot()
        contextSearchText = ""
        contextMatches = []
        contextStatusMessage = "Context pack cleared."
        persistContextLibrary()

        Task {
            await contextIngestionService.removeStoredContent(for: documents)
            await contextIngestionService.clearAllStoredContent()
        }
    }

    func prepareDocumentTrainingData(_ urls: [URL]) {
        guard let url = urls.first else { return }

        Task {
            isPreparingDocument = true
            documentPrepStatusMessage = "Preparing \(url.lastPathComponent)…"

            do {
                let report = try await documentPreparationService.prepareDocument(at: url)
                documentPrepReport = report
                documentPrepStatusMessage = "Built \(report.totalChunkCount) chunks across \(report.totalSectionCount) sections."
            } catch {
                documentPrepStatusMessage = error.localizedDescription
            }

            isPreparingDocument = false
        }
    }

    func exportPreparedDocumentJSONL() {
        guard var report = documentPrepReport else { return }

        Task {
            do {
                let exportURL = try await documentPreparationService.exportJSONL(for: report)
                report.exportedJSONLPath = exportURL.path
                documentPrepReport = report
                documentPrepStatusMessage = "Exported training data to \(exportURL.lastPathComponent)."
            } catch {
                documentPrepStatusMessage = error.localizedDescription
            }
        }
    }

    func revealPreparedDocumentExport() {
        guard let exportPath = documentPrepReport?.exportedJSONLPath else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: exportPath)])
    }

    func clearPreparedDocument() {
        documentPrepReport = nil
        documentPrepStatusMessage = "Drop a Word doc to create sections, chunks, key points, and JSONL export."
    }

    private func run(action: QueuedWidgetAction) async {
        switch action.kind {
        case .dimBedroom:
            let plan = AICommandPlan(
                originalText: "dim \(settings.defaultRoomName) lights",
                room: settings.defaultRoomName,
                light: LightCommand(action: .dim, brightnessPercent: 30),
                music: MusicCommand(),
                seedArtists: [],
                excludedArtists: [],
                moodTags: ["night"],
                confidence: 0.9,
                needsConfirmation: false
            )
            await execute(plan: plan)

        case .playRecommended:
            let title = topRecommendation?.title ?? settings.preferredMoodPreset
            let artist = topRecommendation?.artist ?? "fresh artists"
            let plan = AICommandPlan(
                originalText: "play \(title)",
                room: settings.defaultRoomName,
                light: LightCommand(),
                music: MusicCommand(action: .play, query: "\(title) \(artist)", autoplay: true),
                seedArtists: [],
                excludedArtists: [],
                moodTags: ["cool"],
                confidence: 0.86,
                needsConfirmation: false
            )
            await execute(plan: plan)

        case .refreshRecommendations:
            await refreshRecommendations()

        case .openPanel:
            presentPanel(route: .vibe)

        case .rain:
            let plan = AICommandPlan(
                originalText: "play rain sounds",
                room: settings.defaultRoomName,
                light: LightCommand(),
                music: MusicCommand(action: .rain, query: "rain sounds", autoplay: true),
                seedArtists: [],
                excludedArtists: [],
                moodTags: ["rainy", "calm"],
                confidence: 0.9,
                needsConfirmation: false
            )
            await execute(plan: plan)

        case .setScene:
            let plan = AICommandPlan(
                originalText: action.sceneName ?? "set scene",
                room: settings.defaultRoomName,
                light: LightCommand(action: .scene, sceneName: action.sceneName),
                music: MusicCommand(),
                seedArtists: [],
                excludedArtists: [],
                moodTags: ["scene"],
                confidence: 0.82,
                needsConfirmation: false
            )
            await execute(plan: plan)
        }
    }

    private func execute(plan: AICommandPlan) async {
        var messages = [String]()

        if plan.light.action != .none {
            let roomName = plan.room ?? settings.defaultRoomName
            let result = await homeService.apply(light: plan.light, roomName: roomName, settings: settings)
            widgetSnapshot.lightSummary = result
            messages.append(result)
        }

        if plan.music.action != .none {
            let outcome = await spotifyService.execute(
                command: plan.music,
                seedArtists: plan.seedArtists,
                excludedArtists: plan.excludedArtists,
                moodTags: plan.moodTags,
                settings: settings
            )
            recommendations = outcome.recommendations
            widgetSnapshot.topRecommendation = outcome.recommendations.first
            widgetSnapshot.nowPlaying = outcome.nowPlaying
            messages.append(outcome.status)
            await refreshDiscovery(for: widgetSnapshot.nowPlaying, force: true)
        }

        widgetSnapshot.routeStatus = audioRouteService.currentStatus(preferredOutput: settings.preferredSpeakerName)
        widgetSnapshot.updatedAt = .now
        widgetSnapshot.lastActionResult = messages.isEmpty ? "Scout is ready for the next detour." : messages.joined(separator: " ")
        statusMessage = widgetSnapshot.lastActionResult
        persistSnapshot()
    }

    private func refreshRecommendations() async {
        await refreshDiscovery(for: widgetSnapshot.nowPlaying, force: true, announce: true)
        widgetSnapshot.routeStatus = audioRouteService.currentStatus(preferredOutput: settings.preferredSpeakerName)
        widgetSnapshot.updatedAt = .now
        persistSnapshot()
    }

    private func persistSnapshot() {
        store.saveSnapshot(widgetSnapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func persistContextLibrary() {
        store.saveContextLibrary(contextLibrary)
    }

    private func mergePaperBridgeRun(_ run: PaperBridgeRun) {
        var merged = paperBridgeRecentRuns.filter { $0.id != run.id }
        merged.insert(run, at: 0)
        paperBridgeRecentRuns = Array(merged.prefix(6))
    }

    private func paperBridgeMessage(for run: PaperBridgeRun) -> String {
        if let artifact = run.primaryArtifact {
            return "Run #\(run.runNumber) \(run.stateLabel.lowercased()). \(artifact.name) is ready to download."
        }

        if run.isFinished {
            return "Run #\(run.runNumber) \(run.stateLabel.lowercased()). Check GitHub or Overleaf for the result."
        }

        return "Run #\(run.runNumber) is \(run.stateLabel.lowercased()) on GitHub Actions."
    }

    private func initialPaperBridgeStatusMessage(for settings: AppSettings) -> String {
        if !settings.hasPaperBridgeConfiguration {
            return "Save a GitHub token and connect a repo to start."
        }

        if !hasSavedGitHubToken {
            return "Paper Bridge is configured. Save a GitHub token to fetch runs."
        }

        return "Paper Bridge is ready to dispatch prompts."
    }

    private func normalizeMindDeclutterSessionIfNeeded(silently: Bool = false) {
        guard settings.mindDeclutterEnabled,
              let endsAt = settings.mindDeclutterSessionEndsAt,
              endsAt <= .now else {
            return
        }

        settings.mindDeclutterEnabled = false
        settings.mindDeclutterSessionEndsAt = nil
        persistSettings()

        if !silently {
            statusMessage = hasMindDeclutterDraft
                ? "Mind declutter session wrapped. Your parked tasks are still here."
                : "Mind declutter session wrapped."
        }
    }

    private func normalizedMindDeclutterSessionMinutes(_ minutes: Int) -> Int {
        let supportedMinutes = [15, 30, 60]
        return supportedMinutes.min(by: { abs($0 - minutes) < abs($1 - minutes) }) ?? 30
    }

    private func blockedAndParkedSummary(blockers: Int, parked: Int) -> String {
        var fragments = [String]()
        if blockers > 0 {
            fragments.append("\(blockers) blocker\(blockers == 1 ? "" : "s")")
        }
        if parked > 0 {
            fragments.append("\(parked) parked tab\(parked == 1 ? "" : "s")")
        }
        return fragments.joined(separator: " • ")
    }

    private func copyToPasteboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    private func contextStatusMessage(for report: ContextIngestionService.ImportReport) -> String {
        let indexedCount = report.importedCount + report.refreshedCount

        if indexedCount == 0 {
            if let skippedName = report.skippedNames.first {
                return "Skipped \(skippedName). Drop text-heavy files or folders to index them."
            }
            return "Nothing new was indexed."
        }

        var fragments = [String]()
        if report.importedCount > 0 {
            fragments.append("Added \(report.importedCount) file\(report.importedCount == 1 ? "" : "s")")
        }
        if report.refreshedCount > 0 {
            fragments.append("refreshed \(report.refreshedCount)")
        }

        var message = fragments.joined(separator: ", ")
        if let firstCharacter = message.first {
            message.replaceSubrange(message.startIndex...message.startIndex, with: String(firstCharacter).uppercased())
        }
        message += "."

        if !report.skippedNames.isEmpty {
            message += " Skipped \(report.skippedNames.count)."
        }

        return message
    }

    private func refreshDiscovery(for nowPlaying: MusicNowPlaying, force: Bool = false, announce: Bool = false) async {
        let seedKey = discoverySeedKey(for: nowPlaying)
        guard force || seedKey != lastDiscoverySeedKey || discoveryLanes.isEmpty else {
            return
        }

        isRefreshingDiscovery = true
        let experience = await spotifyService.discoverExperience(from: nowPlaying, settings: settings)
        isRefreshingDiscovery = false
        lastDiscoverySeedKey = seedKey
        scoutBrief = experience.brief

        guard !experience.lanes.isEmpty else {
            recommendations = []
            discoveryLanes = []
            widgetSnapshot.topRecommendation = nil
            if announce {
                widgetSnapshot.lastActionResult = "Connect Spotify so Scout can stop guessing from vibes alone."
                statusMessage = widgetSnapshot.lastActionResult
            }
            return
        }

        let primaryLane = experience.lanes.first
        discoveryLanes = primaryLane.map { [$0] } ?? []
        recommendations = primaryLane.map { [$0.recommendation] } ?? []
        widgetSnapshot.topRecommendation = primaryLane?.recommendation

        if announce {
            let seedLabel = nowPlaying.isPlaying ? nowPlaying.title : "your current mood"
            widgetSnapshot.lastActionResult = primaryLane == nil
                ? "Scout could not lock one exact follow-up for \(seedLabel)."
                : "Scout locked one exact follow-up for \(seedLabel)."
            statusMessage = widgetSnapshot.lastActionResult
        }
    }

    private func shouldRefreshDiscovery(for nowPlaying: MusicNowPlaying) -> Bool {
        discoveryLanes.isEmpty || discoverySeedKey(for: nowPlaying) != lastDiscoverySeedKey
    }

    private func discoverySeedKey(for nowPlaying: MusicNowPlaying) -> String {
        [
            nowPlaying.title.trimmingCharacters(in: .whitespacesAndNewlines),
            nowPlaying.artist.trimmingCharacters(in: .whitespacesAndNewlines),
            nowPlaying.source.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        .joined(separator: "|")
        .lowercased()
    }
}
