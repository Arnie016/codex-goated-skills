import Foundation

enum TradingArchiveLoadState: String, Codable, Sendable {
    case empty
    case syncing
    case live
    case cached
    case error

    var title: String {
        switch self {
        case .empty:
            return "Ready"
        case .syncing:
            return "Syncing"
        case .live:
            return "Live"
        case .cached:
            return "Cached"
        case .error:
            return "Error"
        }
    }
}

enum TradingArchiveWindow: String, Codable, CaseIterable, Identifiable, Sendable {
    case all
    case today
    case week
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .today:
            return "Today"
        case .week:
            return "7D"
        case .favorites:
            return "Saved"
        }
    }
}

enum TradingArchiveSourceHealth: String, Codable, Sendable {
    case live
    case cached
    case failed

    var title: String {
        switch self {
        case .live:
            return "Live"
        case .cached:
            return "Cached"
        case .failed:
            return "Failed"
        }
    }
}

struct TradingArchiveMetric: Identifiable, Sendable {
    let id: String
    let title: String
    let value: String
    let detail: String
}

struct TradingArchiveArticle: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let summary: String
    let sourceName: String
    let sourceURL: URL?
    let articleURL: URL?
    let publishedAt: Date?
    let tags: [String]

    var publishedLabel: String {
        TradingArchiveFormatters.relativeOrAbsoluteDate(for: publishedAt)
    }
}

struct TradingArchiveSourceStatus: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let urlString: String
    let articleCount: Int
    let health: TradingArchiveSourceHealth
    let note: String
}

struct TradingArchiveSnapshot: Codable, Sendable {
    let capturedAt: Date
    let articles: [TradingArchiveArticle]
    let sourceStatuses: [TradingArchiveSourceStatus]

    static let empty = TradingArchiveSnapshot(capturedAt: .distantPast, articles: [], sourceStatuses: [])
}

struct TradingArchivePreferences: Codable, Sendable {
    let sourcesText: String
    let storyLimit: Int
    let window: TradingArchiveWindow
}

enum TradingArchiveFormatters {
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let shortDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func relativeOrAbsoluteDate(for date: Date?) -> String {
        guard let date else { return "Undated" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let relative = formatter.localizedString(for: date, relativeTo: Date())
        if abs(date.timeIntervalSinceNow) < 60 * 60 * 24 * 10 {
            return relative
        }
        return shortDateFormatter.string(from: date)
    }

    static func dashboardTimestamp(for date: Date?) -> String {
        guard let date else { return "No archive yet" }
        return shortDateTimeFormatter.string(from: date)
    }
}
