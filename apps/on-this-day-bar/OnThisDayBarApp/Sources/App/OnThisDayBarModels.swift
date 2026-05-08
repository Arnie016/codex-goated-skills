import Foundation

enum OnThisDayFeedKind: String, CaseIterable, Codable, Identifiable {
    case selected
    case events
    case births
    case deaths
    case holidays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selected:
            return "Selected"
        case .events:
            return "Events"
        case .births:
            return "Births"
        case .deaths:
            return "Deaths"
        case .holidays:
            return "Holidays"
        }
    }

    var subtitle: String {
        switch self {
        case .selected:
            return "Editor-picked anchors"
        case .events:
            return "Broader historical events"
        case .births:
            return "Notable people born"
        case .deaths:
            return "Notable people lost"
        case .holidays:
            return "Observances on this day"
        }
    }
}

enum OnThisDayLoadState: String, Codable, Equatable {
    case syncing
    case live
    case cached
    case error

    var title: String {
        switch self {
        case .syncing:
            return "Syncing"
        case .live:
            return "Live feed"
        case .cached:
            return "Cached snapshot"
        case .error:
            return "Feed error"
        }
    }
}

struct OnThisDayEntry: Codable, Equatable, Identifiable {
    let id: String
    let yearLabel: String
    let numericYear: Int?
    let title: String
    let text: String
    let detail: String
    let pageTags: [String]
    let articleURL: URL?
    let imageURL: URL?
}

struct OnThisDaySnapshot: Codable, Equatable {
    let dateKey: String
    let capturedAt: Date
    let selected: [OnThisDayEntry]
    let events: [OnThisDayEntry]
    let births: [OnThisDayEntry]
    let deaths: [OnThisDayEntry]
    let holidays: [OnThisDayEntry]

    func entries(for kind: OnThisDayFeedKind) -> [OnThisDayEntry] {
        switch kind {
        case .selected:
            return selected
        case .events:
            return events
        case .births:
            return births
        case .deaths:
            return deaths
        case .holidays:
            return holidays
        }
    }

    func count(for kind: OnThisDayFeedKind) -> Int {
        entries(for: kind).count
    }
}

struct OnThisDayPreferences: Codable, Equatable {
    var dateKey: String?
    var activeKind: OnThisDayFeedKind
    var storyLimit: Int
}

struct OnThisDayMetric: Identifiable, Equatable {
    let title: String
    let value: String
    let detail: String

    var id: String { title }
}

enum OnThisDayDateSupport {
    static let singaporeTimeZone = TimeZone(identifier: "Asia/Singapore") ?? .current

    static func calendar(timeZone: TimeZone = singaporeTimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func today(timeZone: TimeZone = singaporeTimeZone) -> Date {
        let calendar = calendar(timeZone: timeZone)
        return calendar.startOfDay(for: Date())
    }

    static func dateKey(for date: Date, timeZone: TimeZone = singaporeTimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func date(from dateKey: String, timeZone: TimeZone = singaporeTimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateKey)
    }

    static func displayTitle(for date: Date, timeZone: TimeZone = singaporeTimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    static func shortLabel(for date: Date, timeZone: TimeZone = singaporeTimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    static func monthDay(for date: Date, timeZone: TimeZone = singaporeTimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar(timeZone: timeZone)
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    static func shifted(date: Date, byDays days: Int, timeZone: TimeZone = singaporeTimeZone) -> Date {
        calendar(timeZone: timeZone).date(byAdding: .day, value: days, to: date) ?? date
    }

    static func randomDate(in year: Int? = nil, timeZone: TimeZone = singaporeTimeZone) -> Date {
        let calendar = calendar(timeZone: timeZone)
        let yearValue = year ?? calendar.component(.year, from: today(timeZone: timeZone))
        let startComponents = DateComponents(year: yearValue, month: 1, day: 1)
        let start = calendar.date(from: startComponents) ?? today(timeZone: timeZone)
        let dayRange = calendar.range(of: .day, in: .year, for: start) ?? 1..<366
        let offset = Int.random(in: dayRange.lowerBound..<dayRange.upperBound)
        return calendar.date(byAdding: .day, value: offset - 1, to: start) ?? start
    }

    static func daySignal(for date: Date, timeZone: TimeZone = singaporeTimeZone) -> String {
        let calendar = calendar(timeZone: timeZone)
        let ordinal = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        return "Day \(ordinal) of the annual timeline"
    }
}
