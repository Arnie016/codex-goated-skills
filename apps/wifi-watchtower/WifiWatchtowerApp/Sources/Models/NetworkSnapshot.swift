import Foundation
import SwiftUI

enum TrustLevel: String, CaseIterable {
    case safe
    case caution
    case avoid

    var title: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .safe:
            return Color(red: 0.13, green: 0.63, blue: 0.43)
        case .caution:
            return Color(red: 0.92, green: 0.59, blue: 0.16)
        case .avoid:
            return Color(red: 0.85, green: 0.25, blue: 0.27)
        }
    }

    var symbolName: String {
        switch self {
        case .safe:
            return "checkmark.shield.fill"
        case .caution:
            return "exclamationmark.shield.fill"
        case .avoid:
            return "xmark.shield.fill"
        }
    }
}

struct SafetyIssue: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let level: TrustLevel
}

struct NearbyNetwork: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let security: String
    let channel: String
    let type: String
    let signal: Int?
    let band: String
    let riskProbability: Int
    let estimatedDistance: String

    var isRisky: Bool {
        riskProbability >= 50
    }

    var safetyLabel: String {
        isRisky ? "Risky" : "Safer"
    }
}

struct ScoreFactor: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let points: Int
    let maxPoints: Int
    let level: TrustLevel
    let detail: String

    var label: String {
        "\(points)/\(maxPoints)"
    }

    var progress: Double {
        guard maxPoints > 0 else { return 0 }
        return Double(points) / Double(maxPoints)
    }
}

struct NetworkSnapshot {
    var networkName: String
    var connectionKind: String?
    var security: String
    var channel: String
    var phyMode: String
    var signal: Int?
    var noise: Int?
    var txRate: Int?
    var gateway: String
    var dnsServers: [String]
    var captivePortal: Bool
    var nearbyInsecureCount: Int
    var nearbyNetworks: [NearbyNetwork]
    var trustLevel: TrustLevel
    var score: Int
    var confidence: Int
    var scoreFactors: [ScoreFactor]
    var issues: [SafetyIssue]
    var guidanceTitle: String
    var guidanceDetail: String
    var lastUpdated: Date

    var headline: String {
        "\(trustLevel.title) • \(networkName)"
    }

    var subheadline: String {
        "\(security) • Ch \(channel)"
    }

    var connectionBadgeText: String? {
        connectionKind
    }

    var bandLabel: String {
        if channel.contains("6GHz") { return "6 GHz" }
        if channel.contains("5GHz") { return "5 GHz" }
        if channel.contains("2GHz") { return "2.4 GHz" }
        return "Band ?"
    }

    var signalLabel: String {
        guard let signal else { return "Unknown" }
        switch signal {
        case -55...0:
            return "Strong"
        case -67 ..< -55:
            return "Good"
        case -75 ..< -67:
            return "Fair"
        default:
            return "Weak"
        }
    }

    var signalBars: Int {
        guard let signal else { return 0 }
        switch signal {
        case -55...0:
            return 4
        case -67 ..< -55:
            return 3
        case -75 ..< -67:
            return 2
        default:
            return 1
        }
    }

    var scoreAccent: Color {
        trustLevel.color
    }

    var nearbySummary: String {
        nearbyInsecureCount == 0 ? "Clean nearby scan" : "\(nearbyInsecureCount) risky nearby"
    }

    var totalNearbyCount: Int {
        nearbyNetworks.count
    }

    var riskyNearbyCount: Int {
        nearbyNetworks.filter(\.isRisky).count
    }

    var saferNearbyCount: Int {
        max(0, totalNearbyCount - riskyNearbyCount)
    }

    var conciseDrivers: [SafetyIssue] {
        issues.filter { $0.level != .safe }.prefix(3).map { $0 }
    }

    var scoreLabel: String {
        "Trust score"
    }

    var scoreSummary: String {
        guidanceDetail
    }

    var shortRecommendation: String {
        guidanceTitle
    }

    var signalNoiseSummary: String {
        guard let signal, let noise else { return "Signal unavailable" }
        return "\(signal) dBm / \(noise) dBm noise"
    }

    static let placeholder = NetworkSnapshot(
        networkName: "Scanning…",
        connectionKind: nil,
        security: "Unknown",
        channel: "--",
        phyMode: "--",
        signal: nil,
        noise: nil,
        txRate: nil,
        gateway: "--",
        dnsServers: [],
        captivePortal: false,
        nearbyInsecureCount: 0,
        nearbyNetworks: [],
        trustLevel: .caution,
        score: 50,
        confidence: 60,
        scoreFactors: [],
        issues: [
            SafetyIssue(title: "Checking network", detail: "Gathering live Wi-Fi, gateway, DNS, and captive portal signals.", level: .caution)
        ],
        guidanceTitle: "Scanning current Wi-Fi",
        guidanceDetail: "Gathering enough signals to grade the network with confidence.",
        lastUpdated: .now
    )
}
