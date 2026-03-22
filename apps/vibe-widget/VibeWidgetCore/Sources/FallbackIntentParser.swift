import Foundation

public enum FallbackIntentParser {
    public static func parse(_ input: String, defaultRoom: String = "Bedroom") -> AICommandPlan {
        let lowered = input.lowercased()

        let room = roomName(from: lowered) ?? defaultRoom
        var light = LightCommand()
        var music = MusicCommand()
        var seedArtists = [String]()
        var excludedArtists = [String]()
        var moodTags = [String]()
        var confidence = 0.62

        if lowered.contains("dim") {
            light.action = .dim
            light.brightnessPercent = 30
            confidence += 0.08
        } else if lowered.contains("lights off") || lowered.contains("turn lights off") || lowered.contains("off") {
            light.action = .off
            confidence += 0.08
        } else if lowered.contains("lights on") || lowered.contains("turn on") {
            light.action = .on
            confidence += 0.08
        }

        if lowered.contains("scene") {
            light.action = .scene
            light.sceneName = titleCase(segment(after: "scene", in: input))
        }

        if lowered.contains("rain") {
            music.action = .rain
            music.query = "rain sounds"
            moodTags.append("rainy")
            confidence += 0.06
        } else if lowered.contains("new artist") || lowered.contains("new artists") {
            music.action = .recommend
            music.query = "fresh emerging artists"
            moodTags += ["fresh", "discovery"]
            confidence += 0.08
        } else if lowered.contains("cool mix") || lowered.contains("something cool") || lowered.contains("play") {
            music.action = lowered.contains("play") ? .play : .recommend
            music.query = titleCase(segment(after: "play", in: input))
            moodTags.append("cool")
            confidence += 0.06
        }

        if let artist = phrase(after: "like", before: "but not", in: input) {
            seedArtists.append(artist)
            moodTags.append("similar-to-\(artist.lowercased())")
            confidence += 0.1
        }

        if let excluded = phrase(after: "but not", before: nil, in: input) {
            excludedArtists.append(excluded)
            confidence += 0.04
        }

        if lowered.contains("vibe") {
            moodTags.append("vibe-led")
        }
        if lowered.contains("chill") || lowered.contains("lower the vibe") {
            moodTags.append("chill")
            if music.action == .none {
                music.action = .chill
                music.query = "chill pop night drive"
            }
        }

        let needsConfirmation = music.action == .none && light.action == .none
        return AICommandPlan(
            originalText: input,
            room: room,
            light: light,
            music: music,
            seedArtists: seedArtists.uniqued(),
            excludedArtists: excludedArtists.uniqued(),
            moodTags: moodTags.uniqued(),
            confidence: min(confidence, 0.96),
            needsConfirmation: needsConfirmation
        )
    }

    private static func roomName(from lowered: String) -> String? {
        ["bedroom", "living room", "office", "kitchen"].first(where: lowered.contains).map { titleCase($0) ?? $0.capitalized }
    }

    private static func phrase(after first: String, before second: String?, in input: String) -> String? {
        let lowered = input.lowercased()
        guard let startRange = lowered.range(of: first) else { return nil }
        let afterStart = lowered[startRange.upperBound...]
        let upperBound = second.flatMap { token in afterStart.range(of: token)?.lowerBound } ?? afterStart.endIndex
        let slice = input[input.index(input.startIndex, offsetBy: lowered.distance(from: lowered.startIndex, to: afterStart.startIndex))..<input.index(input.startIndex, offsetBy: lowered.distance(from: lowered.startIndex, to: upperBound))]
        let trimmed = slice.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func segment(after token: String, in input: String) -> String? {
        let lowered = input.lowercased()
        guard let range = lowered.range(of: token) else { return nil }
        let slice = input[input.index(input.startIndex, offsetBy: lowered.distance(from: lowered.startIndex, to: range.upperBound))...]
        let trimmed = slice.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func titleCase(_ value: String?) -> String? {
        value?.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        Array(Set(self)).sorted { String(describing: $0) < String(describing: $1) }
    }
}
