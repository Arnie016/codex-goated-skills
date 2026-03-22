import AppKit
import SwiftUI
import WidgetKit
import VibeWidgetCore

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var widgetSnapshot: WidgetSnapshot
    @Published var homes: [HomeSummary] = []
    @Published var recommendations: [VibeRecommendation]
    @Published var permissionSnapshot = PermissionSnapshot()
    @Published var commandText = ""
    @Published var parsedPlan: AICommandPlan?
    @Published var isProcessing = false
    @Published var isPanelPresented = false
    @Published var isListening = false
    @Published var statusMessage = "Ready to start the next vibe."

    let store: SharedStore

    private let homeService = HomeService()
    private let spotifyService = SpotifyService()
    private let aiCommandService = AICommandService()
    private let permissionService = PermissionService()
    private let speechCapture = SpeechCaptureService()
    private let audioRouteService = AudioRouteService()

    private var hasBootstrapped = false

    init(store: SharedStore = .shared) {
        self.store = store
        settings = store.loadSettings()
        widgetSnapshot = store.loadSnapshot()
        recommendations = widgetSnapshot.topRecommendation.map { [$0] } ?? []
        statusMessage = widgetSnapshot.lastActionResult
    }

    var topRecommendation: VibeRecommendation? {
        widgetSnapshot.topRecommendation ?? recommendations.first
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
        homes = await homeService.fetchHomes()
        if settings.selectedHomeID == nil, let firstHome = homes.first {
            settings.selectedHomeID = firstHome.id
            settings.selectedHomeName = firstHome.name
            persistSettings()
        }

        permissionSnapshot = await permissionService.refresh(homeAvailable: !homes.isEmpty)
        widgetSnapshot.routeStatus = audioRouteService.currentStatus(preferredOutput: settings.preferredSpeakerName)
        widgetSnapshot.nowPlaying = await spotifyService.currentNowPlaying()

        if recommendations.isEmpty {
            let basePlan = AICommandPlan(
                originalText: settings.preferredMoodPreset,
                room: settings.defaultRoomName,
                light: LightCommand(),
                music: MusicCommand(action: .recommend, query: settings.preferredMoodPreset, autoplay: false),
                seedArtists: [],
                excludedArtists: [],
                moodTags: ["cool", "fresh"],
                confidence: 0.72,
                needsConfirmation: false
            )
            recommendations = await spotifyService.recommendTracks(for: basePlan, settings: settings)
            widgetSnapshot.topRecommendation = recommendations.first
        }

        if widgetSnapshot.lastActionResult.isEmpty {
            widgetSnapshot.lastActionResult = "Ready to start the next vibe."
        }

        persistSnapshot()
    }

    func persistSettings() {
        store.saveSettings(settings)
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
                    statusMessage = "Spotify login did not complete."
                }
            } else {
                isPanelPresented = true
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
            statusMessage = "Spotify sign-in opened in your browser."
        } catch {
            statusMessage = "Add a Spotify client ID before connecting."
        }
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
            isPanelPresented = true
        }
    }

    func performQuickAction(_ kind: WidgetActionKind) {
        Task {
            await run(action: QueuedWidgetAction(kind: kind))
        }
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
            isPanelPresented = true
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
                statusMessage = "Listening for the next vibe."
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
            isPanelPresented = true

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
        }

        widgetSnapshot.routeStatus = audioRouteService.currentStatus(preferredOutput: settings.preferredSpeakerName)
        widgetSnapshot.updatedAt = .now
        widgetSnapshot.lastActionResult = messages.isEmpty ? "Ready for the next vibe." : messages.joined(separator: " ")
        statusMessage = widgetSnapshot.lastActionResult
        persistSnapshot()
    }

    private func refreshRecommendations() async {
        let plan = AICommandPlan(
            originalText: settings.preferredMoodPreset,
            room: settings.defaultRoomName,
            light: LightCommand(),
            music: MusicCommand(action: .recommend, query: settings.preferredMoodPreset, autoplay: false),
            seedArtists: [],
            excludedArtists: [],
            moodTags: ["cool", "fresh", "discovery"],
            confidence: 0.8,
            needsConfirmation: false
        )

        recommendations = await spotifyService.recommendTracks(for: plan, settings: settings)
        widgetSnapshot.topRecommendation = recommendations.first
        widgetSnapshot.routeStatus = audioRouteService.currentStatus(preferredOutput: settings.preferredSpeakerName)
        widgetSnapshot.lastActionResult = "Pinned a new top vibe."
        widgetSnapshot.updatedAt = .now
        statusMessage = widgetSnapshot.lastActionResult
        persistSnapshot()
    }

    private func persistSnapshot() {
        store.saveSnapshot(widgetSnapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
