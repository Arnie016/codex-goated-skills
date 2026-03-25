import Foundation

public enum LightSceneAction: String, Codable, CaseIterable, Sendable {
    case none
    case dim
    case off
    case on
    case scene
}

public enum MusicIntentAction: String, Codable, CaseIterable, Sendable {
    case none
    case play
    case recommend
    case rain
    case chill
}

public enum AudioRouteAvailability: String, Codable, Sendable {
    case connected
    case available
    case missing
}

public struct LightCommand: Codable, Hashable, Sendable {
    public var action: LightSceneAction
    public var brightnessPercent: Int?
    public var sceneName: String?

    public init(action: LightSceneAction = .none, brightnessPercent: Int? = nil, sceneName: String? = nil) {
        self.action = action
        self.brightnessPercent = brightnessPercent
        self.sceneName = sceneName
    }
}

public struct MusicCommand: Codable, Hashable, Sendable {
    public var action: MusicIntentAction
    public var query: String?
    public var autoplay: Bool

    public init(action: MusicIntentAction = .none, query: String? = nil, autoplay: Bool = true) {
        self.action = action
        self.query = query
        self.autoplay = autoplay
    }
}

public struct AICommandPlan: Codable, Hashable, Sendable {
    public var originalText: String
    public var room: String?
    public var light: LightCommand
    public var music: MusicCommand
    public var seedArtists: [String]
    public var excludedArtists: [String]
    public var moodTags: [String]
    public var confidence: Double
    public var needsConfirmation: Bool

    public init(
        originalText: String,
        room: String? = nil,
        light: LightCommand = LightCommand(),
        music: MusicCommand = MusicCommand(),
        seedArtists: [String] = [],
        excludedArtists: [String] = [],
        moodTags: [String] = [],
        confidence: Double = 0.5,
        needsConfirmation: Bool = false
    ) {
        self.originalText = originalText
        self.room = room
        self.light = light
        self.music = music
        self.seedArtists = seedArtists
        self.excludedArtists = excludedArtists
        self.moodTags = moodTags
        self.confidence = confidence
        self.needsConfirmation = needsConfirmation
    }
}

public struct VibeRecommendation: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var artist: String
    public var subtitle: String
    public var spotifyURI: String?
    public var reason: String

    public init(id: String = UUID().uuidString, title: String, artist: String, subtitle: String, spotifyURI: String? = nil, reason: String) {
        self.id = id
        self.title = title
        self.artist = artist
        self.subtitle = subtitle
        self.spotifyURI = spotifyURI
        self.reason = reason
    }
}

public struct RoomSummary: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct SceneSummary: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct HomeSummary: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var rooms: [RoomSummary]
    public var scenes: [SceneSummary]

    public init(id: String, name: String, rooms: [RoomSummary] = [], scenes: [SceneSummary] = []) {
        self.id = id
        self.name = name
        self.rooms = rooms
        self.scenes = scenes
    }
}

public struct MusicNowPlaying: Codable, Hashable, Sendable {
    public var title: String
    public var artist: String
    public var source: String
    public var isPlaying: Bool

    public init(title: String = "Nothing playing", artist: String = "Pick a vibe to start", source: String = "Spotify", isPlaying: Bool = false) {
        self.title = title
        self.artist = artist
        self.source = source
        self.isPlaying = isPlaying
    }
}

public struct AudioRouteStatus: Codable, Hashable, Sendable {
    public var preferredOutput: String
    public var currentOutput: String
    public var availability: AudioRouteAvailability

    public init(preferredOutput: String = "PartyBox", currentOutput: String = "Mac Speakers", availability: AudioRouteAvailability = .missing) {
        self.preferredOutput = preferredOutput
        self.currentOutput = currentOutput
        self.availability = availability
    }
}

public struct PermissionSnapshot: Codable, Hashable, Sendable {
    public enum State: String, Codable, Sendable {
        case unknown
        case granted
        case denied
    }

    public var microphone: State
    public var speech: State
    public var home: State
    public var automation: State

    public init(microphone: State = .unknown, speech: State = .unknown, home: State = .unknown, automation: State = .unknown) {
        self.microphone = microphone
        self.speech = speech
        self.home = home
        self.automation = automation
    }
}

public struct WidgetSnapshot: Codable, Hashable, Sendable {
    public var nowPlaying: MusicNowPlaying
    public var topRecommendation: VibeRecommendation?
    public var routeStatus: AudioRouteStatus
    public var lightSummary: String
    public var lastActionResult: String
    public var updatedAt: Date

    public init(
        nowPlaying: MusicNowPlaying = MusicNowPlaying(),
        topRecommendation: VibeRecommendation? = nil,
        routeStatus: AudioRouteStatus = AudioRouteStatus(),
        lightSummary: String = "Bedroom lights ready",
        lastActionResult: String = "Scout is on standby for the next obsession.",
        updatedAt: Date = .now
    ) {
        self.nowPlaying = nowPlaying
        self.topRecommendation = topRecommendation
        self.routeStatus = routeStatus
        self.lightSummary = lightSummary
        self.lastActionResult = lastActionResult
        self.updatedAt = updatedAt
    }
}

public struct AppSettings: Codable, Hashable, Sendable {
    public var hasCompletedOnboarding: Bool
    public var selectedHomeID: String?
    public var selectedHomeName: String
    public var defaultRoomName: String
    public var preferredSpeakerName: String
    public var spotifyClientID: String
    public var openAIKeyServiceName: String
    public var preferredMoodPreset: String
    public var githubTokenServiceName: String
    public var paperRepositoryOwner: String
    public var paperRepositoryName: String
    public var paperWorkflowIdentifier: String
    public var paperRepositoryRef: String
    public var paperOverleafProjectID: String
    public var paperArtifactName: String
    public var paperMainTeXPath: String
    public var paperLastRunID: Int?
    public var mindDeclutterEnabled: Bool
    public var mindDeclutterInboxText: String
    public var mindDeclutterFocusText: String
    public var mindDeclutterSessionEndsAt: Date?
    public var mindDeclutterSessionMinutes: Int

    private enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case selectedHomeID
        case selectedHomeName
        case defaultRoomName
        case preferredSpeakerName
        case spotifyClientID
        case openAIKeyServiceName
        case preferredMoodPreset
        case githubTokenServiceName
        case paperRepositoryOwner
        case paperRepositoryName
        case paperWorkflowIdentifier
        case paperRepositoryRef
        case paperOverleafProjectID
        case paperArtifactName
        case paperMainTeXPath
        case paperLastRunID
        case mindDeclutterEnabled
        case mindDeclutterInboxText
        case mindDeclutterFocusText
        case mindDeclutterSessionEndsAt
        case mindDeclutterSessionMinutes
    }

    public init(
        hasCompletedOnboarding: Bool = false,
        selectedHomeID: String? = nil,
        selectedHomeName: String = "My Home",
        defaultRoomName: String = "Bedroom",
        preferredSpeakerName: String = "PartyBox",
        spotifyClientID: String = "",
        openAIKeyServiceName: String = VibeAppGroup.openAIKeyService,
        preferredMoodPreset: String = "Cool Mix",
        githubTokenServiceName: String = VibeAppGroup.githubTokenService,
        paperRepositoryOwner: String = "",
        paperRepositoryName: String = "",
        paperWorkflowIdentifier: String = "overleaf-bridge.yml",
        paperRepositoryRef: String = "main",
        paperOverleafProjectID: String = "",
        paperArtifactName: String = "paper-output",
        paperMainTeXPath: String = "main.tex",
        paperLastRunID: Int? = nil,
        mindDeclutterEnabled: Bool = false,
        mindDeclutterInboxText: String = "",
        mindDeclutterFocusText: String = "",
        mindDeclutterSessionEndsAt: Date? = nil,
        mindDeclutterSessionMinutes: Int = 30
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedHomeID = selectedHomeID
        self.selectedHomeName = selectedHomeName
        self.defaultRoomName = defaultRoomName
        self.preferredSpeakerName = preferredSpeakerName
        self.spotifyClientID = spotifyClientID
        self.openAIKeyServiceName = openAIKeyServiceName
        self.preferredMoodPreset = preferredMoodPreset
        self.githubTokenServiceName = githubTokenServiceName
        self.paperRepositoryOwner = paperRepositoryOwner
        self.paperRepositoryName = paperRepositoryName
        self.paperWorkflowIdentifier = paperWorkflowIdentifier
        self.paperRepositoryRef = paperRepositoryRef
        self.paperOverleafProjectID = paperOverleafProjectID
        self.paperArtifactName = paperArtifactName
        self.paperMainTeXPath = paperMainTeXPath
        self.paperLastRunID = paperLastRunID
        self.mindDeclutterEnabled = mindDeclutterEnabled
        self.mindDeclutterInboxText = mindDeclutterInboxText
        self.mindDeclutterFocusText = mindDeclutterFocusText
        self.mindDeclutterSessionEndsAt = mindDeclutterSessionEndsAt
        self.mindDeclutterSessionMinutes = mindDeclutterSessionMinutes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        selectedHomeID = try container.decodeIfPresent(String.self, forKey: .selectedHomeID)
        selectedHomeName = try container.decodeIfPresent(String.self, forKey: .selectedHomeName) ?? "My Home"
        defaultRoomName = try container.decodeIfPresent(String.self, forKey: .defaultRoomName) ?? "Bedroom"
        preferredSpeakerName = try container.decodeIfPresent(String.self, forKey: .preferredSpeakerName) ?? "PartyBox"
        spotifyClientID = try container.decodeIfPresent(String.self, forKey: .spotifyClientID) ?? ""
        openAIKeyServiceName = try container.decodeIfPresent(String.self, forKey: .openAIKeyServiceName) ?? VibeAppGroup.openAIKeyService
        preferredMoodPreset = try container.decodeIfPresent(String.self, forKey: .preferredMoodPreset) ?? "Cool Mix"
        githubTokenServiceName = try container.decodeIfPresent(String.self, forKey: .githubTokenServiceName) ?? VibeAppGroup.githubTokenService
        paperRepositoryOwner = try container.decodeIfPresent(String.self, forKey: .paperRepositoryOwner) ?? ""
        paperRepositoryName = try container.decodeIfPresent(String.self, forKey: .paperRepositoryName) ?? ""
        paperWorkflowIdentifier = try container.decodeIfPresent(String.self, forKey: .paperWorkflowIdentifier) ?? "overleaf-bridge.yml"
        paperRepositoryRef = try container.decodeIfPresent(String.self, forKey: .paperRepositoryRef) ?? "main"
        paperOverleafProjectID = try container.decodeIfPresent(String.self, forKey: .paperOverleafProjectID) ?? ""
        paperArtifactName = try container.decodeIfPresent(String.self, forKey: .paperArtifactName) ?? "paper-output"
        paperMainTeXPath = try container.decodeIfPresent(String.self, forKey: .paperMainTeXPath) ?? "main.tex"
        paperLastRunID = try container.decodeIfPresent(Int.self, forKey: .paperLastRunID)
        mindDeclutterEnabled = try container.decodeIfPresent(Bool.self, forKey: .mindDeclutterEnabled) ?? false
        mindDeclutterInboxText = try container.decodeIfPresent(String.self, forKey: .mindDeclutterInboxText) ?? ""
        mindDeclutterFocusText = try container.decodeIfPresent(String.self, forKey: .mindDeclutterFocusText) ?? ""
        mindDeclutterSessionEndsAt = try container.decodeIfPresent(Date.self, forKey: .mindDeclutterSessionEndsAt)
        mindDeclutterSessionMinutes = try container.decodeIfPresent(Int.self, forKey: .mindDeclutterSessionMinutes) ?? 30
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encodeIfPresent(selectedHomeID, forKey: .selectedHomeID)
        try container.encode(selectedHomeName, forKey: .selectedHomeName)
        try container.encode(defaultRoomName, forKey: .defaultRoomName)
        try container.encode(preferredSpeakerName, forKey: .preferredSpeakerName)
        try container.encode(spotifyClientID, forKey: .spotifyClientID)
        try container.encode(openAIKeyServiceName, forKey: .openAIKeyServiceName)
        try container.encode(preferredMoodPreset, forKey: .preferredMoodPreset)
        try container.encode(githubTokenServiceName, forKey: .githubTokenServiceName)
        try container.encode(paperRepositoryOwner, forKey: .paperRepositoryOwner)
        try container.encode(paperRepositoryName, forKey: .paperRepositoryName)
        try container.encode(paperWorkflowIdentifier, forKey: .paperWorkflowIdentifier)
        try container.encode(paperRepositoryRef, forKey: .paperRepositoryRef)
        try container.encode(paperOverleafProjectID, forKey: .paperOverleafProjectID)
        try container.encode(paperArtifactName, forKey: .paperArtifactName)
        try container.encode(paperMainTeXPath, forKey: .paperMainTeXPath)
        try container.encodeIfPresent(paperLastRunID, forKey: .paperLastRunID)
        try container.encode(mindDeclutterEnabled, forKey: .mindDeclutterEnabled)
        try container.encode(mindDeclutterInboxText, forKey: .mindDeclutterInboxText)
        try container.encode(mindDeclutterFocusText, forKey: .mindDeclutterFocusText)
        try container.encodeIfPresent(mindDeclutterSessionEndsAt, forKey: .mindDeclutterSessionEndsAt)
        try container.encode(mindDeclutterSessionMinutes, forKey: .mindDeclutterSessionMinutes)
    }
}

public enum WidgetActionKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case dimBedroom
    case playRecommended
    case refreshRecommendations
    case openPanel
    case rain
    case setScene

    public var id: String { rawValue }
}

public struct QueuedWidgetAction: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var kind: WidgetActionKind
    public var sceneName: String?

    public init(id: UUID = UUID(), kind: WidgetActionKind, sceneName: String? = nil) {
        self.id = id
        self.kind = kind
        self.sceneName = sceneName
    }
}
