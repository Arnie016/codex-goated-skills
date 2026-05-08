import Foundation

protocol TradingArchiveFeedFetching: Sendable {
    func fetch(from feedURLs: [URL]) async throws -> TradingArchiveSnapshot
}

enum TradingArchiveFeedError: LocalizedError {
    case noFeedsConfigured
    case allFeedsFailed([String])

    var errorDescription: String? {
        switch self {
        case .noFeedsConfigured:
            return "No feed URLs were configured."
        case .allFeedsFailed(let notes):
            return notes.isEmpty
                ? "All configured feeds failed to load."
                : "All configured feeds failed to load: \(notes.joined(separator: " | "))"
        }
    }
}

struct TradingArchiveParsedFeed {
    let sourceTitle: String
    let articles: [TradingArchiveArticle]
}

struct LiveTradingArchiveFeedService: TradingArchiveFeedFetching, Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(from feedURLs: [URL]) async throws -> TradingArchiveSnapshot {
        guard !feedURLs.isEmpty else {
            throw TradingArchiveFeedError.noFeedsConfigured
        }

        var combinedArticles: [TradingArchiveArticle] = []
        var sourceStatuses: [TradingArchiveSourceStatus] = []
        var failures: [String] = []

        for feedURL in feedURLs {
            do {
                var request = URLRequest(url: feedURL)
                request.setValue("application/rss+xml, application/atom+xml, application/xml, text/xml", forHTTPHeaderField: "Accept")
                request.setValue("codex-goated-skills/trading-archive-bar", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
                    throw NSError(domain: "TradingArchiveHTTP", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"
                    ])
                }

                let parsed = try Self.parseFeed(data: data, sourceURL: feedURL)
                combinedArticles.append(contentsOf: parsed.articles)
                sourceStatuses.append(
                    TradingArchiveSourceStatus(
                        id: feedURL.absoluteString,
                        title: parsed.sourceTitle,
                        urlString: feedURL.absoluteString,
                        articleCount: parsed.articles.count,
                        health: .live,
                        note: parsed.articles.isEmpty ? "Feed loaded but no articles matched." : "Loaded \(parsed.articles.count) archived articles."
                    )
                )
            } catch {
                failures.append("\(feedURL.host() ?? feedURL.absoluteString): \(error.localizedDescription)")
                sourceStatuses.append(
                    TradingArchiveSourceStatus(
                        id: feedURL.absoluteString,
                        title: feedURL.host() ?? feedURL.absoluteString,
                        urlString: feedURL.absoluteString,
                        articleCount: 0,
                        health: .failed,
                        note: error.localizedDescription
                    )
                )
            }
        }

        if combinedArticles.isEmpty, !sourceStatuses.contains(where: { $0.health == .live }) {
            throw TradingArchiveFeedError.allFeedsFailed(failures)
        }

        let deduped = dedupeAndSort(combinedArticles)
        return TradingArchiveSnapshot(capturedAt: Date(), articles: deduped, sourceStatuses: sourceStatuses)
    }

    static func parseFeed(data: Data, sourceURL: URL) throws -> TradingArchiveParsedFeed {
        let parser = TradingArchiveXMLFeedParser(sourceURL: sourceURL)
        return try parser.parse(data: data)
    }

    private func dedupeAndSort(_ articles: [TradingArchiveArticle]) -> [TradingArchiveArticle] {
        var seen = Set<String>()
        let sorted = articles.sorted {
            switch ($0.publishedAt, $1.publishedAt) {
            case let (lhs?, rhs?):
                return lhs > rhs
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }

        return sorted.filter { article in
            let key = (article.articleURL?.absoluteString ?? article.id).lowercased()
            return seen.insert(key).inserted
        }
    }
}

final class TradingArchiveXMLFeedParser: NSObject, XMLParserDelegate {
    private struct WorkingEntry {
        var title = ""
        var link = ""
        var summary = ""
        var published = ""
        var categories: [String] = []
        var guid = ""
    }

    private let sourceURL: URL
    private var sourceTitle = ""
    private var isAtom = false
    private var currentElement = ""
    private var currentText = ""
    private var currentEntry: WorkingEntry?
    private var entries: [WorkingEntry] = []
    private var parserError: Error?

    init(sourceURL: URL) {
        self.sourceURL = sourceURL
    }

    func parse(data: Data) throws -> TradingArchiveParsedFeed {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse(), parserError == nil else {
            throw parserError ?? parser.parserError ?? NSError(
                domain: "TradingArchiveParser",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not parse feed."]
            )
        }

        let sourceName = sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (sourceURL.host() ?? "Feed")
            : sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        let articles = entries.enumerated().map { index, entry in
            TradingArchiveArticle(
                id: buildID(for: entry, index: index),
                title: clean(entry.title).isEmpty ? "Untitled article" : clean(entry.title),
                summary: clean(entry.summary),
                sourceName: sourceName,
                sourceURL: sourceURL,
                articleURL: URL(string: entry.link.trimmingCharacters(in: .whitespacesAndNewlines)),
                publishedAt: TradingArchiveDateParser.parse(entry.published),
                tags: Array(Set(entry.categories.map(clean).filter { !$0.isEmpty })).sorted()
            )
        }

        return TradingArchiveParsedFeed(sourceTitle: sourceName, articles: articles)
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        parserError = parseError
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName.lowercased()
        currentText = ""
        if currentElement == "feed" {
            isAtom = true
        }
        if currentElement == "item" || currentElement == "entry" {
            currentEntry = WorkingEntry()
        }
        if isAtom, currentElement == "link", currentEntry != nil, let href = attributeDict["href"], !href.isEmpty {
            currentEntry?.link = href
        }
        if isAtom, currentElement == "category", currentEntry != nil {
            if let term = attributeDict["term"], !term.isEmpty {
                currentEntry?.categories.append(term)
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = elementName.lowercased()

        if var entry = currentEntry {
            switch key {
            case "title":
                if entry.title.isEmpty {
                    entry.title = value
                }
            case "description", "summary", "content":
                if entry.summary.isEmpty {
                    entry.summary = value
                }
            case "pubdate", "published", "updated":
                if entry.published.isEmpty {
                    entry.published = value
                }
            case "link":
                if entry.link.isEmpty {
                    entry.link = value
                }
            case "guid", "id":
                if entry.guid.isEmpty {
                    entry.guid = value
                }
            case "category":
                if !value.isEmpty {
                    entry.categories.append(value)
                }
            case "item", "entry":
                entries.append(entry)
                currentEntry = nil
            default:
                break
            }
            currentEntry = currentEntry == nil ? nil : entry
        } else if key == "title", sourceTitle.isEmpty, !value.isEmpty {
            sourceTitle = value
        }

        currentText = ""
    }

    private func clean(_ text: String) -> String {
        text
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func buildID(for entry: WorkingEntry, index: Int) -> String {
        let base = [entry.guid, entry.link, entry.title, sourceURL.absoluteString, "\(index)"]
            .first(where: { !$0.isEmpty }) ?? UUID().uuidString
        return base.lowercased()
    }
}

enum TradingArchiveDateParser {
    private static let formatters: [DateFormatter] = {
        let specs = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        ]

        return specs.map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            return formatter
        }
    }()

    static func parse(_ raw: String) -> Date? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        for formatter in formatters {
            if let date = formatter.date(from: text) {
                return date
            }
        }
        return ISO8601DateFormatter().date(from: text)
    }
}
