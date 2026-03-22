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
        lastActionResult: String = "Waiting for your next vibe move.",
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

    public init(
        hasCompletedOnboarding: Bool = false,
        selectedHomeID: String? = nil,
        selectedHomeName: String = "My Home",
        defaultRoomName: String = "Bedroom",
        preferredSpeakerName: String = "PartyBox",
        spotifyClientID: String = "",
        openAIKeyServiceName: String = VibeAppGroup.openAIKeyService,
        preferredMoodPreset: String = "Cool Mix"
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedHomeID = selectedHomeID
        self.selectedHomeName = selectedHomeName
        self.defaultRoomName = defaultRoomName
        self.preferredSpeakerName = preferredSpeakerName
        self.spotifyClientID = spotifyClientID
        self.openAIKeyServiceName = openAIKeyServiceName
        self.preferredMoodPreset = preferredMoodPreset
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
