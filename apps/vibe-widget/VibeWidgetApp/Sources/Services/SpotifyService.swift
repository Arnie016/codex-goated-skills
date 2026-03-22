import AppKit
import CryptoKit
import Foundation
import VibeWidgetCore

struct MusicExecutionOutcome {
    var recommendations: [VibeRecommendation]
    var nowPlaying: MusicNowPlaying
    var status: String
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
        return "Spotify is connected."
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

    func recommendTracks(for plan: AICommandPlan, settings: AppSettings) async -> [VibeRecommendation] {
        if let token = try? await validAccessToken(clientID: settings.spotifyClientID),
           let liveResults = try? await searchTracks(query: searchQuery(for: plan), accessToken: token, excluding: plan.excludedArtists),
           !liveResults.isEmpty {
            return Array(liveResults.prefix(3))
        }
        return fallbackRecommendations(for: plan)
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

        var recommendations = await recommendTracks(for: plan, settings: settings)
        let status: String

        if command.autoplay, let first = recommendations.first {
            if let uri = first.spotifyURI, play(uri: uri) {
                status = "Playing \(first.title) on Spotify."
            } else {
                openSearch(query: first.title + " " + first.artist)
                status = "Opened Spotify with the top vibe ready."
            }
        } else if command.action == .rain {
            openSearch(query: "rain sounds")
            status = "Opened rain sounds in Spotify."
        } else {
            status = "Pinned three fresh picks to the vibe stack."
        }

        if command.action == .rain, recommendations.isEmpty {
            recommendations = fallbackRecommendations(for: plan)
        }

        let nowPlaying = await currentNowPlaying()
        return MusicExecutionOutcome(recommendations: recommendations, nowPlaying: nowPlaying, status: status)
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

    private func fallbackRecommendations(for plan: AICommandPlan) -> [VibeRecommendation] {
        let anchor = plan.seedArtists.first ?? "Justin Bieber"
        let mood = plan.moodTags.first ?? "night-pop"
        return [
            VibeRecommendation(title: "Shimmer Driver", artist: "Lune Avenue", subtitle: "Fresh pop night drive", reason: "Close to \(anchor), but a newer lane."),
            VibeRecommendation(title: "Afterglow Arcade", artist: "North Static", subtitle: "Late-night gloss", reason: "Matches the \(mood) brief."),
            VibeRecommendation(title: "Rain on Franklin", artist: "Velvet Youth", subtitle: "Soft atmospheric lift", reason: "Easy transition for the PartyBox.")
        ]
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
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
