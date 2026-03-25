import CryptoKit
import Foundation

struct FlightRiskFeedService: Sendable {
    struct RiskFetchResult: Sendable {
        let source: TravelRiskSourceDefinition
        let headlines: [TravelRiskHeadline]
        let fingerprint: String
        let failureCount: Int
    }

    func fetch(
        source: TravelRiskSourceDefinition,
        origin: FlightPlace,
        destination: FlightPlace,
        departureDate: Date,
        returnDate: Date,
        now: Date = Date()
    ) async -> RiskFetchResult {
        guard let url = source.resolvedURL(
            origin: origin,
            destination: destination,
            departureDate: departureDate,
            returnDate: returnDate
        ) else {
            return RiskFetchResult(source: source, headlines: [], fingerprint: "invalid", failureCount: 1)
        }

        if source.parserStrategy == .openMeteoForecast {
            return RiskFetchResult(source: source, headlines: [], fingerprint: "weather", failureCount: 0)
        }

        do {
            let data = try await loadData(from: url)
            let headlines = parseRSS(data: data, source: source, now: now)
            return RiskFetchResult(
                source: source,
                headlines: headlines,
                fingerprint: fingerprint(for: headlines),
                failureCount: 0
            )
        } catch {
            return RiskFetchResult(
                source: source,
                headlines: [],
                fingerprint: "error",
                failureCount: 1
            )
        }
    }

    static func dueSources(
        routeID: String,
        sources: [TravelRiskSourceDefinition],
        cache: [String: TravelRiskSourceCacheEntry],
        now: Date = Date()
    ) -> [TravelRiskSourceDefinition] {
        sources.filter { source in
            let cacheKey = "\(routeID)::\(source.id)"
            guard let cached = cache[cacheKey] else { return true }
            let interval = cached.failureCount == 0 ? source.refreshTier.interval : source.refreshTier.interval * 2
            return now.timeIntervalSince(cached.lastFetchedAt) >= interval
        }
    }

    static func hydrateHealth(
        routeID: String,
        sources: [TravelRiskSourceDefinition],
        cache: [String: TravelRiskSourceCacheEntry]
    ) -> [TravelRiskSourceHealth] {
        sources.map { source in
            let cacheKey = "\(routeID)::\(source.id)"
            let cached = cache[cacheKey]
            return TravelRiskSourceHealth(
                id: cacheKey,
                displayName: source.displayName,
                category: source.category,
                refreshTier: source.refreshTier,
                lastFetchedAt: cached?.lastFetchedAt,
                itemCount: cached?.headlines.count ?? 0,
                failureCount: cached?.failureCount ?? 0
            )
        }
    }

    private func parseRSS(
        data: Data,
        source: TravelRiskSourceDefinition,
        now: Date
    ) -> [TravelRiskHeadline] {
        RSSFeedParser.parse(data: data).prefix(source.maxItems).compactMap { item in
            guard let url = URL(string: item.link) else { return nil }
            return TravelRiskHeadline(
                id: "\(source.id)::\(url.absoluteString)",
                sourceName: source.providerName,
                category: source.category,
                title: item.title,
                summary: item.summary,
                articleURL: url,
                publishedAt: item.publishedAt,
                weight: source.baseWeight
            )
        }
    }

    private func loadData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Mozilla/5.0 FlightScout", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func fingerprint(for headlines: [TravelRiskHeadline]) -> String {
        let joined = headlines.map { "\($0.id)|\($0.title)|\($0.summary)" }.joined(separator: "\n")
        let digest = SHA256.hash(data: Data(joined.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private struct RSSFeedItem: Sendable {
    let title: String
    let link: String
    let summary: String
    let publishedAt: Date?
}

private enum RSSFeedParser {
    static func parse(data: Data) -> [RSSFeedItem] {
        let delegate = RSSFeedParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.items
    }
}

private final class RSSFeedParserDelegate: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var insideItem = false

    private let dateFormatters: [DateFormatter] = {
        let rfc822 = DateFormatter()
        rfc822.locale = Locale(identifier: "en_US_POSIX")
        rfc822.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"

        let rfc822Short = DateFormatter()
        rfc822Short.locale = Locale(identifier: "en_US_POSIX")
        rfc822Short.dateFormat = "EEE, dd MMM yyyy HH:mm Z"

        let iso8601 = ISO8601DateFormatter()

        let isoFormatter = DateFormatter()
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        return [rfc822, rfc822Short, isoFormatter].map { formatter in
            let copy = DateFormatter()
            copy.locale = formatter.locale
            copy.dateFormat = formatter.dateFormat
            return copy
        } + {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            return [formatter]
        }()
    }()

    private(set) var items: [RSSFeedItem] = []

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName.lowercased()
        if currentElement == "item" || currentElement == "entry" {
            insideItem = true
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
        }

        if insideItem, currentElement == "link", let href = attributeDict["href"], !href.isEmpty {
            currentLink = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            currentLink += string
        case "description", "summary", "content":
            currentDescription += string
        case "pubdate", "published", "updated":
            currentPubDate += string
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let lowered = elementName.lowercased()
        if lowered == "item" || lowered == "entry" {
            insideItem = false
            guard !currentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            items.append(
                RSSFeedItem(
                    title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                    summary: strippedHTML(currentDescription).trimmingCharacters(in: .whitespacesAndNewlines),
                    publishedAt: parseDate(currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))
                )
            )
        }
        currentElement = ""
    }

    private func parseDate(_ value: String) -> Date? {
        guard !value.isEmpty else { return nil }
        for formatter in dateFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return ISO8601DateFormatter().date(from: value)
    }

    private func strippedHTML(_ string: String) -> String {
        string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
