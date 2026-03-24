import Foundation

struct MindDeclutterPlan: Equatable {
    let suggestedFocusTask: String?
    let focusTask: String?
    let blockers: [String]
    let parkingLot: [String]
    let parkingCount: Int
    let overflowCount: Int
    let itemCount: Int
    let blockerCount: Int
    let actionableCount: Int

    init(inboxText: String, focusText: String) {
        let items = Self.extractItems(from: inboxText)
        let trimmedFocus = Self.cleanFragment(focusText)

        suggestedFocusTask = Self.resolveSuggestedFocus(from: items)
        focusTask = trimmedFocus.isEmpty ? suggestedFocusTask : trimmedFocus

        blockers = items
            .filter { $0.bucket == .blocker }
            .map(\.text)

        var remainingItems = items
            .filter { $0.bucket != .blocker }
            .map(\.text)
        if let focusTask,
           let matchingIndex = remainingItems.firstIndex(where: { Self.normalizedKey(for: $0) == Self.normalizedKey(for: focusTask) }) {
            remainingItems.remove(at: matchingIndex)
        }

        parkingLot = Array(remainingItems.prefix(3))
        parkingCount = remainingItems.count
        overflowCount = max(0, remainingItems.count - parkingLot.count)
        itemCount = items.count
        blockerCount = blockers.count
        actionableCount = max(0, itemCount - blockerCount)
    }

    var hasCapture: Bool {
        itemCount > 0
    }

    private enum Bucket: Equatable {
        case focus
        case later
        case blocker
        case inbox
    }

    private struct ParsedItem: Equatable {
        let text: String
        let bucket: Bucket
    }

    private static func extractItems(from text: String) -> [ParsedItem] {
        let normalizedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedText.isEmpty else { return [] }

        let lineItems = normalizedText
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { parseFragment(String($0)) }

        if lineItems.count > 1 {
            return uniqueStable(lineItems)
        }

        let sentenceItems = normalizedText
            .replacingOccurrences(of: "•", with: "\n")
            .replacingOccurrences(of: ";", with: "\n")
            .replacingOccurrences(of: ". ", with: ".\n")
            .replacingOccurrences(of: "? ", with: "?\n")
            .replacingOccurrences(of: "! ", with: "!\n")
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { parseFragment(String($0)) }

        return uniqueStable(sentenceItems)
    }

    private static func resolveSuggestedFocus(from items: [ParsedItem]) -> String? {
        if let labeledFocus = items.first(where: { $0.bucket == .focus }) {
            return labeledFocus.text
        }

        if let firstActionable = items.first(where: { $0.bucket == .inbox || $0.bucket == .later }) {
            return firstActionable.text
        }

        return nil
    }

    private static func parseFragment(_ fragment: String) -> ParsedItem? {
        let cleaned = cleanFragment(fragment)
        guard !cleaned.isEmpty else { return nil }
        return ParsedItem(text: cleaned, bucket: bucket(for: fragment))
    }

    private static func bucket(for fragment: String) -> Bucket {
        let normalized = fragment
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let focusPrefixes = ["now", "next", "focus", "first"]
        let laterPrefixes = ["later", "park", "someday", "backlog"]
        let blockerPrefixes = ["blocker", "waiting", "stuck", "blocked"]

        if matches(prefixes: focusPrefixes, in: normalized) {
            return .focus
        }

        if matches(prefixes: blockerPrefixes, in: normalized) {
            return .blocker
        }

        if matches(prefixes: laterPrefixes, in: normalized) {
            return .later
        }

        return .inbox
    }

    private static func cleanFragment(_ fragment: String) -> String {
        var cleaned = fragment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "" }

        let leadingPatterns = [
            #"^[\-\*\•\·\▪\◦]+\s*"#,
            #"^\[[xX ]\]\s*"#,
            #"^\d+[\.\)]\s*"#
        ]

        for pattern in leadingPatterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }

        cleaned = cleaned.replacingOccurrences(
            of: #"^(now|next|focus|first|later|park|someday|backlog|blocker|waiting|stuck|blocked)\b[:\-]?\s*"#,
            with: "",
            options: .regularExpression
        )

        cleaned = cleaned
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".,;:!?")))

        return cleaned
    }

    private static func uniqueStable(_ items: [ParsedItem]) -> [ParsedItem] {
        var seen = Set<String>()
        var result = [ParsedItem]()

        for item in items {
            let key = normalizedKey(for: item.text)
            guard !key.isEmpty, seen.insert(key).inserted else { continue }
            result.append(item)
        }

        return result
    }

    private static func matches(prefixes: [String], in text: String) -> Bool {
        prefixes.contains { prefix in
            text.hasPrefix("\(prefix):") ||
            text.hasPrefix("\(prefix)-") ||
            text == prefix ||
            text.hasPrefix("\(prefix) ")
        }
    }

    private static func normalizedKey(for text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
