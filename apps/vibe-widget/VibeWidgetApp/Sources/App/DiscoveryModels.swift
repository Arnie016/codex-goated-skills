import Foundation
import VibeWidgetCore

enum DiscoveryLaneKind: String, CaseIterable, Identifiable, Sendable {
    case complement = "complement"
    case supplement = "supplement"
    case polarOpposite = "polar_opposite"
    case newArtist = "new_artist"
    case differentCategory = "different_category"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .complement:
            return "Complement"
        case .supplement:
            return "Supplement"
        case .polarOpposite:
            return "Polar Opposite"
        case .newArtist:
            return "New Artist"
        case .differentCategory:
            return "Different Category"
        }
    }

    var systemImage: String {
        switch self {
        case .complement:
            return "sparkles"
        case .supplement:
            return "plus.circle.fill"
        case .polarOpposite:
            return "arrow.left.arrow.right.circle.fill"
        case .newArtist:
            return "person.crop.circle.badge.plus"
        case .differentCategory:
            return "square.stack.3d.up.fill"
        }
    }

    var tintSeed: (Double, Double, Double) {
        switch self {
        case .complement:
            return (0.18, 0.63, 0.37)
        case .supplement:
            return (0.28, 0.38, 0.34)
        case .polarOpposite:
            return (0.42, 0.32, 0.30)
        case .newArtist:
            return (0.30, 0.32, 0.38)
        case .differentCategory:
            return (0.43, 0.37, 0.28)
        }
    }

    init?(apiValue: String) {
        let normalized = apiValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        switch normalized {
        case "complement":
            self = .complement
        case "supplement":
            self = .supplement
        case "opposite", "polar_opposite":
            self = .polarOpposite
        case "new_artist", "breakout":
            self = .newArtist
        case "different_category", "left_turn", "genre_jump":
            self = .differentCategory
        default:
            return nil
        }
    }
}

struct DiscoveryLane: Identifiable, Hashable, Sendable {
    let kind: DiscoveryLaneKind
    let recommendation: VibeRecommendation
    let searchQuery: String

    var id: String {
        "\(kind.rawValue)-\(recommendation.id)"
    }
}

struct DiscoveryScoutBrief: Hashable, Sendable {
    let mood: String
    let summary: String
    let quip: String

    static let placeholder = DiscoveryScoutBrief(
        mood: "Scout warming up",
        summary: "Queue a song in Spotify and the scout will start reading the room.",
        quip: "We love a dramatic pause, apparently."
    )
}

struct DiscoveryExperience: Sendable {
    let lanes: [DiscoveryLane]
    let brief: DiscoveryScoutBrief
}
