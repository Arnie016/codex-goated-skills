import AppKit
import CryptoKit
import Foundation
import VibeWidgetCore

struct MusicExecutionOutcome {
    var recommendations: [VibeRecommendation]
    var nowPlaying: MusicNowPlaying
    var status: String
}

enum RecommendationLaunchOutcome {
    case played
    case revealed
    case unresolved
}

@MainActor
final class SpotifyService {
    private struct SpotifyTokenEnvelope: Codable {
        var accessToken: String
        var refreshToken: String
        var expiresAt: Date
    }

    private struct TokenResponse: Decodable {
        let access_token: String
        let refresh_token: String?
        let expires_in: Int
    }

    private struct SearchResponse: Decodable {
        struct Tracks: Decodable {
            let items: [Track]
        }

        struct Track: Decodable {
            struct Artist: Decodable {
                let name: String
            }

            let id: String
            let name: String
            let uri: String
            let artists: [Artist]
        }

        let tracks: Tracks
    }

    private struct DiscoveryQueryPlan: Codable {
        let lane: String
        let subtitle: String
        let query: String
        let reason: String
        let avoidSeedArtist: Bool

        init(kind: DiscoveryLaneKind, subtitle: String, query: String, reason: String, avoidSeedArtist: Bool) {
            self.lane = kind.rawValue
            self.subtitle = subtitle
            self.query = query
            self.reason = reason
            self.avoidSeedArtist = avoidSeedArtist
        }

        var kind: DiscoveryLaneKind? {
            DiscoveryLaneKind(apiValue: lane)
        }
    }

    private struct DiscoverySeed {
        let title: String
        let artist: String
        let promptAnchor: String
    }

    private struct DiscoveryPlanEnvelope: Codable {
        let mood: String
        let summary: String
        let quip: String
        let lanes: [DiscoveryQueryPlan]
    }

    private struct DiscoveryPlanningResult {
        let brief: DiscoveryScoutBrief
        let plans: [DiscoveryQueryPlan]
    }

    private let keychain = KeychainSecretStore()
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: VibeAppGroup.identifier) ?? .standard
    }

    func authorizationURL(clientID: String) throws -> URL {
        guard !clientID.isEmpty else { throw URLError(.badURL) }
        let verifier = randomVerifier()
        defaults.set(verifier, forKey: VibeAppGroup.spotifyCodeVerifierKey)

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            .init(name: "response_type", value: "code"),
            .init(name: "client_id", value: clientID),
            .init(name: "redirect_uri", value: "vibewidget://spotify-callback"),
            .init(name: "scope", value: "user-read-playback-state user-modify-playback-state user-read-currently-playing"),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge", value: challenge(for: verifier))
        ]
        return components.url!
    }

    func handleCallback(_ url: URL, clientID: String) async throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let verifier = defaults.string(forKey: VibeAppGroup.spotifyCodeVerifierKey) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncoded([
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": "vibewidget://spotify-callback",
            "client_id": clientID,
            "code_verifier": verifier
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        try saveToken(SpotifyTokenEnvelope(
            accessToken: token.access_token,
            refreshToken: token.refresh_token ?? token.access_token,
            expiresAt: .now.addingTimeInterval(TimeInterval(token.expires_in - 30))
        ))
        return "Spotify is connected. Scout has clearance."
    }

    func currentNowPlaying() async -> MusicNowPlaying {
        if let spotify = runAppleScript("""
            tell application "Spotify"
                if running then
                    return (player state as string) & "||" & (name of current track) & "||" & (artist of current track)
                end if
            end tell
            return "stopped||Nothing playing||Pick a vibe to start"
            """) {
            let parts = spotify.components(separatedBy: "||")
            if parts.count >= 3 {
                return MusicNowPlaying(
                    title: parts[1],
                    artist: parts[2],
                    source: "Spotify",
                    isPlaying: parts[0].contains("playing")
                )
            }
        }

        if let music = runAppleScript("""
            tell application "Music"
                if running then
                    return (player state as string) & "||" & (name of current track) & "||" & (artist of current track)
                end if
            end tell
            return "stopped||Nothing playing||Pick a vibe to start"
            """) {
            let parts = music.components(separatedBy: "||")
            if parts.count >= 3 {
                return MusicNowPlaying(
                    title: parts[1],
                    artist: parts[2],
                    source: "Music",
                    isPlaying: parts[0].contains("playing")
                )
            }
        }

        return MusicNowPlaying()
    }

    func discoverExperience(from nowPlaying: MusicNowPlaying, settings: AppSettings) async -> DiscoveryExperience {
        let seed = discoverySeed(from: nowPlaying, settings: settings)
        let planning = (try? await discoveryPlanningResult(for: seed, nowPlaying: nowPlaying, settings: settings))
            ?? fallbackDiscoveryPlanningResult(for: seed, nowPlaying: nowPlaying)

        guard let accessToken = try? await validAccessToken(clientID: settings.spotifyClientID) else {
            return DiscoveryExperience(
                lanes: [],
                brief: DiscoveryScoutBrief(
                    mood: planning.brief.mood,
                    summary: "Connect Spotify if you want direct track picks instead of tasteful guesswork.",
                    quip: "Mystery is nice. Playable songs are nicer."
                )
            )
        }

        var lanes: [DiscoveryLane] = []
        var seenRecommendationIDs = Set<String>()

        for kind in DiscoveryLaneKind.allCases {
            guard let plan = planning.plans.first(where: { $0.kind == kind }) else { continue }
            let liveResults = (try? await searchTracks(query: plan.query, accessToken: accessToken, excluding: [])) ?? []
            guard let recommendation = pickDiscoveryRecommendation(
                from: liveResults,
                seed: seed,
                avoidSeedArtist: plan.avoidSeedArtist,
                seenRecommendationIDs: seenRecommendationIDs
            ) else {
                continue
            }

            seenRecommendationIDs.insert(recommendation.id)
            lanes.append(
                DiscoveryLane(
                    kind: kind,
                    recommendation: VibeRecommendation(
                        id: recommendation.id,
                        title: recommendation.title,
                        artist: recommendation.artist,
                        subtitle: plan.subtitle,
                        spotifyURI: recommendation.spotifyURI,
                        reason: plan.reason
                    ),
                    searchQuery: plan.query
                )
            )
        }

        if lanes.isEmpty {
            return DiscoveryExperience(
                lanes: [],
                brief: DiscoveryScoutBrief(
                    mood: planning.brief.mood,
                    summary: "Spotify did not return reliable track matches, so Scout refused to fake it.",
                    quip: "Inventing songs felt ambitious, even for me."
                )
            )
        }

        return DiscoveryExperience(lanes: lanes, brief: planning.brief)
    }

    func recommendTracks(for plan: AICommandPlan, settings: AppSettings) async -> [VibeRecommendation] {
        if let token = try? await validAccessToken(clientID: settings.spotifyClientID),
           let liveResults = try? await searchTracks(query: searchQuery(for: plan), accessToken: token, excluding: plan.excludedArtists),
           !liveResults.isEmpty {
            return Array(liveResults.prefix(1))
        }
        return []
    }

    func execute(command: MusicCommand, seedArtists: [String], excludedArtists: [String], moodTags: [String], settings: AppSettings) async -> MusicExecutionOutcome {
        let plan = AICommandPlan(
            originalText: command.query ?? settings.preferredMoodPreset,
            room: settings.defaultRoomName,
            light: LightCommand(),
            music: command,
            seedArtists: seedArtists,
            excludedArtists: excludedArtists,
            moodTags: moodTags,
            confidence: 0.7,
            needsConfirmation: false
        )

        let recommendations = await recommendTracks(for: plan, settings: settings)
        let status: String

        if command.autoplay, let first = recommendations.first {
            switch launchRecommendation(first, revealInSpotify: false) {
            case .played:
                status = "Playing \(first.title) on Spotify."
            case .revealed:
                status = "Opened \(first.title) in Spotify. Playback chose drama."
            case .unresolved:
                status = "Scout could not lock one exact Spotify track to autoplay."
            }
        } else if command.action == .rain {
            openSearch(query: "rain sounds")
            status = "Opened rain sounds in Spotify."
        } else if command.autoplay {
            status = "Connect Spotify so Scout can autoplay exact tracks, not guesses."
        } else {
            status = recommendations.isEmpty
                ? "Connect Spotify to load real track recommendations."
                : "Scout pinned one exact follow-up for later."
        }

        let nowPlaying = await currentNowPlaying()
        return MusicExecutionOutcome(recommendations: recommendations, nowPlaying: nowPlaying, status: status)
    }

    func playRecommendation(
        _ recommendation: VibeRecommendation,
        revealInSpotify: Bool = true
    ) async -> RecommendationLaunchOutcome {
        launchRecommendation(recommendation, revealInSpotify: revealInSpotify)
    }

    func openCurrentTrack(from nowPlaying: MusicNowPlaying) {
        guard nowPlaying.isPlaying else { return }

        if nowPlaying.source == "Spotify" {
            if let trackURL = runAppleScript("""
                tell application "Spotify"
                    if running then
                        activate
                        return spotify url of current track
                    end if
                end tell
                return ""
                """),
               let url = URL(string: trackURL),
               !trackURL.isEmpty {
                NSWorkspace.shared.open(url)
                return
            }

            _ = runAppleScript("""
                tell application "Spotify"
                    activate
                end tell
                """)
            return
        }

        if nowPlaying.source == "Music" {
            _ = runAppleScript("""
                tell application "Music"
                    activate
                end tell
                """)
        }
    }

    private func searchTracks(query: String, accessToken: String, excluding artists: [String]) async throws -> [VibeRecommendation] {
        var components = URLComponents(string: "https://api.spotify.com/v1/search")!
        components.queryItems = [
            .init(name: "q", value: query),
            .init(name: "type", value: "track"),
            .init(name: "limit", value: "8")
        ]

        var request = URLRequest(url: components.url!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        let excluded = Set(artists.map { $0.lowercased() })

        return decoded.tracks.items.compactMap { track in
            let artistName = track.artists.map(\.name).joined(separator: ", ")
            if excluded.contains(where: { artistName.lowercased().contains($0) }) {
                return nil
            }
            return VibeRecommendation(
                id: track.id,
                title: track.name,
                artist: artistName,
                subtitle: "Spotify match",
                spotifyURI: track.uri,
                reason: "Live Spotify result for your vibe."
            )
        }
    }

    private func validAccessToken(clientID: String) async throws -> String {
        guard !clientID.isEmpty else { throw URLError(.userAuthenticationRequired) }
        let envelope = try loadToken()
        if envelope.expiresAt > .now {
            return envelope.accessToken
        }

        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncoded([
            "grant_type": "refresh_token",
            "refresh_token": envelope.refreshToken,
            "client_id": clientID
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.userAuthenticationRequired)
        }

        let refreshed = try JSONDecoder().decode(TokenResponse.self, from: data)
        let updated = SpotifyTokenEnvelope(
            accessToken: refreshed.access_token,
            refreshToken: refreshed.refresh_token ?? envelope.refreshToken,
            expiresAt: .now.addingTimeInterval(TimeInterval(refreshed.expires_in - 30))
        )
        try saveToken(updated)
        return updated.accessToken
    }

    private func saveToken(_ token: SpotifyTokenEnvelope) throws {
        let data = try JSONEncoder().encode(token)
        let string = String(decoding: data, as: UTF8.self)
        try keychain.write(service: VibeAppGroup.spotifyAccessService, value: string)
    }

    private func loadToken() throws -> SpotifyTokenEnvelope {
        let raw = try keychain.read(service: VibeAppGroup.spotifyAccessService)
        let data = Data(raw.utf8)
        return try JSONDecoder().decode(SpotifyTokenEnvelope.self, from: data)
    }

    private func discoverySeed(from nowPlaying: MusicNowPlaying, settings: AppSettings) -> DiscoverySeed {
        let title = nowPlaying.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = nowPlaying.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasLiveTrack = !title.isEmpty &&
            !artist.isEmpty &&
            title.caseInsensitiveCompare("Nothing playing") != .orderedSame &&
            artist.caseInsensitiveCompare("Pick a vibe to start") != .orderedSame

        if hasLiveTrack {
            return DiscoverySeed(
                title: title,
                artist: artist,
                promptAnchor: "\"\(title)\" by \(artist)"
            )
        }

        return DiscoverySeed(
            title: settings.preferredMoodPreset,
            artist: "discovery seed",
            promptAnchor: "a listener who wants \(settings.preferredMoodPreset)"
        )
    }

    private func discoveryPlanningResult(
        for seed: DiscoverySeed,
        nowPlaying: MusicNowPlaying,
        settings: AppSettings
    ) async throws -> DiscoveryPlanningResult {
        let apiKey = try keychain.read(service: settings.openAIKeyServiceName)
        guard !apiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        let schemaPrompt = """
        Return only minified JSON as a single object with keys:
        mood:string,
        summary:string,
        quip:string,
        lanes:array.
        The lanes array must contain exactly 5 objects.
        Allowed lane values: complement, supplement, opposite, new_artist, different_category.
        Each lane object must contain:
        lane:string,
        subtitle:string,
        query:string,
        reason:string,
        avoidSeedArtist:boolean.
        Rules:
        - mood must be 2 to 4 words.
        - summary must be one sentence under 16 words describing the emotional context.
        - quip must be one playful dry-sarcastic sentence under 12 words, never mean.
        - complement: a smooth next-song handoff, usually a different artist.
        - supplement: same universe, deep cut, remix, or same-artist side path.
        - opposite: a deliberate contrast that still feels rewarding.
        - new_artist: less obvious artist with similar appeal.
        - different_category: a genre jump or category pivot.
        - subtitle must be 4 words or fewer.
        - query must be a concise Spotify song search query, not a playlist request.
        - reason must be one short sentence under 12 words.
        """

        let userPrompt = """
        Build discovery lanes based on \(seed.promptAnchor).
        The result should feel like a smart top-bar music scout on macOS.
        The current player source is \(nowPlaying.source) and playback is \(nowPlaying.isPlaying ? "active" : "idle").
        """

        let payload: [String: Any] = [
            "model": "gpt-4.1-mini",
            "input": [
                [
                    "role": "system",
                    "content": [["type": "input_text", "text": schemaPrompt]]
                ],
                [
                    "role": "user",
                    "content": [["type": "input_text", "text": userPrompt]]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data)
        let textOutput = extractText(from: json) ?? ""
        let jsonString = firstJSONObject(in: textOutput) ?? textOutput
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }

        let decoded = try JSONDecoder().decode(DiscoveryPlanEnvelope.self, from: jsonData)
        let mappedPlans = decoded.lanes.compactMap { plan -> DiscoveryQueryPlan? in
            guard let kind = plan.kind else { return nil }
            return DiscoveryQueryPlan(
                kind: kind,
                subtitle: trimmed(plan.subtitle, fallback: kind.title),
                query: trimmed(plan.query, fallback: "\(seed.title) \(seed.artist)"),
                reason: trimmed(plan.reason, fallback: "A strong next lane from this song."),
                avoidSeedArtist: plan.avoidSeedArtist
            )
        }

        if mappedPlans.isEmpty {
            throw URLError(.cannotParseResponse)
        }

        return DiscoveryPlanningResult(
            brief: DiscoveryScoutBrief(
                mood: trimmed(decoded.mood, fallback: fallbackMood(for: seed, nowPlaying: nowPlaying)),
                summary: trimmed(decoded.summary, fallback: fallbackSummary(for: seed, nowPlaying: nowPlaying)),
                quip: trimmed(decoded.quip, fallback: fallbackQuip(for: seed, nowPlaying: nowPlaying))
            ),
            plans: mappedPlans
        )
    }

    private func fallbackDiscoveryPlanningResult(
        for seed: DiscoverySeed,
        nowPlaying: MusicNowPlaying
    ) -> DiscoveryPlanningResult {
        DiscoveryPlanningResult(
            brief: DiscoveryScoutBrief(
                mood: fallbackMood(for: seed, nowPlaying: nowPlaying),
                summary: fallbackSummary(for: seed, nowPlaying: nowPlaying),
                quip: fallbackQuip(for: seed, nowPlaying: nowPlaying)
            ),
            plans: fallbackDiscoveryPlans(for: seed)
        )
    }

    private func fallbackDiscoveryPlans(for seed: DiscoverySeed) -> [DiscoveryQueryPlan] {
        [
            DiscoveryQueryPlan(
                kind: .complement,
                subtitle: "Easy handoff",
                query: "\(seed.title) \(seed.artist) dream pop",
                reason: "Stays close without replaying the same move.",
                avoidSeedArtist: true
            ),
            DiscoveryQueryPlan(
                kind: .supplement,
                subtitle: "Same orbit",
                query: "\(seed.artist) deep cut",
                reason: "Keeps the same DNA with a side-angle pick.",
                avoidSeedArtist: false
            ),
            DiscoveryQueryPlan(
                kind: .polarOpposite,
                subtitle: "Sharp contrast",
                query: "moody electronic left turn",
                reason: "Flips the mood for a clean contrast.",
                avoidSeedArtist: true
            ),
            DiscoveryQueryPlan(
                kind: .newArtist,
                subtitle: "Fresh voice",
                query: "new artist like \(seed.artist)",
                reason: "Pushes discovery toward a less obvious artist.",
                avoidSeedArtist: true
            ),
            DiscoveryQueryPlan(
                kind: .differentCategory,
                subtitle: "Genre jump",
                query: "cross genre night drive",
                reason: "Moves sideways into a different category.",
                avoidSeedArtist: true
            )
        ]
    }

    private func fallbackMood(for seed: DiscoverySeed, nowPlaying: MusicNowPlaying) -> String {
        let normalizedSeed = normalize("\(seed.title) \(seed.artist)")

        if containsAny(in: normalizedSeed, keywords: ["dream", "moon", "night", "midnight", "haze", "apocalypse"]) {
            return "Dreamy spiral"
        }

        if containsAny(in: normalizedSeed, keywords: ["rain", "blue", "slow", "shadow", "tears", "ghost"]) {
            return "Moody drift"
        }

        if containsAny(in: normalizedSeed, keywords: ["party", "dance", "fire", "rush", "heat", "gold"]) {
            return "Electric lift"
        }

        return nowPlaying.isPlaying ? "Locked-in glow" : "Tasteful standby"
    }

    private func fallbackSummary(for seed: DiscoverySeed, nowPlaying: MusicNowPlaying) -> String {
        switch fallbackMood(for: seed, nowPlaying: nowPlaying) {
        case "Dreamy spiral":
            return "Floaty, cinematic, and clearly not interested in behaving normally."
        case "Moody drift":
            return "Heavy atmosphere, sharp edges, and enough melancholy to decorate a room."
        case "Electric lift":
            return "High-gloss energy with just enough chaos to stay interesting."
        case "Locked-in glow":
            return "Confident, melodic, and suspiciously good at setting a scene."
        default:
            return "No live track yet, so Scout is improvising with alarming confidence."
        }
    }

    private func fallbackQuip(for seed: DiscoverySeed, nowPlaying: MusicNowPlaying) -> String {
        switch fallbackMood(for: seed, nowPlaying: nowPlaying) {
        case "Dreamy spiral":
            return "Subtle. Like glitter in a wind tunnel."
        case "Moody drift":
            return "Very chill, if we ignore the emotional weather."
        case "Electric lift":
            return "A measured amount of chaos. Allegedly."
        case "Locked-in glow":
            return "Tasteful. Annoyingly tasteful, even."
        default:
            return "Silence is bold. Scout disagrees, but still."
        }
    }

    private func containsAny(in value: String, keywords: [String]) -> Bool {
        keywords.contains { value.contains($0) }
    }

    private func pickDiscoveryRecommendation(
        from recommendations: [VibeRecommendation],
        seed: DiscoverySeed,
        avoidSeedArtist: Bool,
        seenRecommendationIDs: Set<String>
    ) -> VibeRecommendation? {
        let normalizedSeedTitle = normalize(seed.title)
        let normalizedSeedArtist = normalize(seed.artist)

        let differentArtistFirstPass = recommendations.first { recommendation in
            !seenRecommendationIDs.contains(recommendation.id) &&
            normalize(recommendation.title) != normalizedSeedTitle &&
            normalize(recommendation.artist) != normalizedSeedArtist
        }

        if avoidSeedArtist, let differentArtistFirstPass {
            return differentArtistFirstPass
        }

        return recommendations.first { recommendation in
            !seenRecommendationIDs.contains(recommendation.id) &&
            normalize(recommendation.title) != normalizedSeedTitle
        }
    }

    private func searchQuery(for plan: AICommandPlan) -> String {
        var parts = [String]()
        if let query = plan.music.query, !query.isEmpty {
            parts.append(query)
        }
        parts.append(contentsOf: plan.seedArtists)
        if !plan.moodTags.isEmpty {
            parts.append(plan.moodTags.joined(separator: " "))
        }
        if parts.isEmpty {
            parts.append("cool mix")
        }
        return parts.joined(separator: " ")
    }

    private func play(uri: String) -> Bool {
        runAppleScript("""
            tell application "Spotify"
                activate
                play track "\(uri)"
            end tell
            """) != nil
    }

    private func launchRecommendation(
        _ recommendation: VibeRecommendation,
        revealInSpotify: Bool
    ) -> RecommendationLaunchOutcome {
        guard let uri = recommendation.spotifyURI,
              let expectedTrackID = spotifyTrackID(from: uri) else {
            return .unresolved
        }

        if playExactTrack(uri: uri, expectedTrackID: expectedTrackID) {
            if revealInSpotify {
                _ = openExactTrack(uri: uri)
            }
            return .played
        }

        if revealInSpotify, openExactTrack(uri: uri) {
            return .revealed
        }

        return .unresolved
    }

    private func playExactTrack(uri: String, expectedTrackID: String) -> Bool {
        guard let currentTrackReference = runAppleScript("""
            tell application "Spotify"
                activate
                play track "\(uri)"
                delay 0.4
                return spotify url of current track
            end tell
            """),
            let currentTrackID = spotifyTrackID(from: currentTrackReference) else {
            return false
        }

        return currentTrackID == expectedTrackID
    }

    private func openExactTrack(uri: String) -> Bool {
        guard let trackID = spotifyTrackID(from: uri),
              let deepLink = URL(string: "spotify:track:\(trackID)") else {
            return false
        }

        return NSWorkspace.shared.open(deepLink)
    }

    private func spotifyTrackID(from reference: String) -> String? {
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("spotify:track:") {
            return trimmed.components(separatedBy: ":").last
        }

        guard let url = URL(string: trimmed) else {
            return nil
        }

        let components = url.pathComponents.filter { $0 != "/" }
        guard let trackIndex = components.firstIndex(of: "track"),
              trackIndex + 1 < components.count else {
            return nil
        }

        return components[trackIndex + 1]
    }

    private func openSearch(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "spotify:search:\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        let result = script?.executeAndReturnError(&error)
        if error != nil {
            return nil
        }
        return result?.stringValue
    }

    private func formEncoded(_ values: [String: String]) -> Data? {
        let body = values
            .map { key, value in
                let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(escapedKey)=\(escapedValue)"
            }
            .joined(separator: "&")
        return body.data(using: .utf8)
    }

    private func randomVerifier() -> String {
        let bytes = (0..<64).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64URLEncodedString()
    }

    private func challenge(for verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64URLEncodedString()
    }

    private func extractText(from value: Any) -> String? {
        if let string = value as? String, (string.contains("{") || string.contains("[")) {
            return string
        }
        if let dictionary = value as? [String: Any] {
            if let outputText = dictionary["output_text"] as? String {
                return outputText
            }
            for nested in dictionary.values {
                if let match = extractText(from: nested) {
                    return match
                }
            }
        }
        if let array = value as? [Any] {
            for item in array {
                if let match = extractText(from: item) {
                    return match
                }
            }
        }
        return nil
    }

    private func firstJSONArray(in string: String) -> String? {
        guard let start = string.firstIndex(of: "["), let end = string.lastIndex(of: "]") else {
            return nil
        }
        return String(string[start...end])
    }

    private func firstJSONObject(in string: String) -> String? {
        guard let start = string.firstIndex(of: "{"), let end = string.lastIndex(of: "}") else {
            return nil
        }
        return String(string[start...end])
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private func trimmed(_ value: String, fallback: String) -> String {
        let candidate = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return candidate.isEmpty ? fallback : candidate
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
