import Foundation

struct FlightPriceSearchService: Sendable {
    func search(query: FlightSearchQuery, settings: FlightScoutSettings, now: Date = Date()) async -> FlightSearchResult {
        if settings.priceProviderMode != .publicSignalsOnly,
           let apiKey = ProcessInfo.processInfo.environment["SERPAPI_API_KEY"],
           !apiKey.isEmpty,
           let exact = try? await searchSerpAPI(query: query, apiKey: apiKey, now: now),
           !exact.isEmpty {
            return FlightSearchResult(
                routeID: routeID(for: query),
                quotes: exact,
                mode: .exactAPI,
                statusMessage: nil
            )
        }

        let publicQuotes = (try? await searchPublicSignals(query: query, now: now)) ?? []
        let fallback = publicQuotes.isEmpty ? deeplinkFallbackQuotes(query: query, now: now) : publicQuotes
        let status = publicQuotes.isEmpty
            ? "Using public booking links and travel signals. Add SERPAPI_API_KEY for stronger exact fare coverage."
            : "Using public fare signals and booking pages."

        return FlightSearchResult(
            routeID: routeID(for: query),
            quotes: fallback,
            mode: .publicSignal,
            statusMessage: status
        )
    }

    private func searchSerpAPI(query: FlightSearchQuery, apiKey: String, now: Date) async throws -> [FlightQuote] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let departure = formatter.string(from: query.departureDate)
        let returning = formatter.string(from: query.returnDate)

        var components = URLComponents(string: "https://serpapi.com/search.json")!
        components.queryItems = [
            .init(name: "engine", value: "google_flights"),
            .init(name: "departure_id", value: query.origin.iataCode),
            .init(name: "arrival_id", value: query.destination.iataCode),
            .init(name: "outbound_date", value: departure),
            .init(name: "return_date", value: returning),
            .init(name: "currency", value: query.currencyCode),
            .init(name: "type", value: "1"),
            .init(name: "api_key", value: apiKey)
        ]

        let data = try await loadData(from: components.url!)
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
        let groups = ["best_flights", "other_flights"].compactMap { root[$0] as? [[String: Any]] }
        let flattened = groups.flatMap { $0 }

        return flattened.prefix(6).compactMap { item in
            let price = item["price"] as? Double ?? Double(item["price"] as? Int ?? 0)
            let bookingTokens = item["booking_token"] as? [[String: Any]]
            let fallbackLink = FlightScoutFormatting.googleFlightsURL(
                origin: query.origin.iataCode,
                destination: query.destination.iataCode,
                departureDate: query.departureDate,
                returnDate: query.returnDate
            )

            let title = (item["flights"] as? [[String: Any]])?.first.flatMap { flight in
                [flight["airline"] as? String, flight["flight_number"] as? String].compactMap { $0 }.joined(separator: " ")
            } ?? "\(query.origin.iataCode) to \(query.destination.iataCode)"

            let totalDuration = item["total_duration"] as? Int ?? 0
            let durationText = totalDuration > 0 ? "\(totalDuration / 60)h \(totalDuration % 60)m" : "See live details"
            let stopCount = ((item["layovers"] as? [[String: Any]])?.count ?? 0)
            let stopsText = stopCount == 0 ? "Direct" : "\(stopCount) stop"

            let bookingURL = bookingTokens?
                .compactMap { $0["link"] as? String }
                .compactMap(URL.init(string:))
                .first ?? fallbackLink

            return FlightQuote(
                id: "serpapi::\(query.origin.iataCode)::\(query.destination.iataCode)::\(bookingURL.absoluteString)",
                providerName: "Google Flights",
                title: title,
                totalPrice: price > 0 ? price : nil,
                currencyCode: query.currencyCode,
                stopsText: stopsText,
                durationText: durationText,
                summary: "Exact fare result from live flight search.",
                sourceURL: fallbackLink,
                bookingURL: bookingURL,
                fetchedAt: now,
                confidenceScore: price > 0 ? 96 : 80
            )
        }
    }

    private func searchPublicSignals(query: FlightSearchQuery, now: Date) async throws -> [FlightQuote] {
        let searches: [(String, String)] = [
            ("Skyscanner", "\"\(query.origin.city)\" to \"\(query.destination.city)\" flights \(query.departureDate.formatted(date: .abbreviated, time: .omitted)) site:skyscanner.com"),
            ("Kayak", "\"\(query.origin.city)\" to \"\(query.destination.city)\" flights \(query.departureDate.formatted(date: .abbreviated, time: .omitted)) site:kayak.com"),
            ("Google Flights", "\"\(query.origin.city)\" to \"\(query.destination.city)\" flights \(query.departureDate.formatted(date: .abbreviated, time: .omitted)) \"Google Flights\""),
            ("Travel Deals", "\"\(query.origin.city)\" to \"\(query.destination.city)\" flight deal")
        ]

        var quotes: [FlightQuote] = []
        for (provider, searchText) in searches {
            let results = try await searchDuckDuckGo(searchText: searchText)
            let mapped = await withTaskGroup(of: FlightQuote?.self, returning: [FlightQuote].self) { group in
                for result in results.prefix(2) {
                    group.addTask {
                        await self.makePublicQuote(
                            provider: provider,
                            result: result,
                            query: query,
                            now: now
                        )
                    }
                }

                var built: [FlightQuote] = []
                for await quote in group {
                    if let quote {
                        built.append(quote)
                    }
                }
                return built
            }
            quotes.append(contentsOf: mapped)
        }

        let keyed = Dictionary(grouping: quotes, by: { $0.bookingURL.absoluteString }).compactMapValues { $0.max(by: { $0.confidenceScore < $1.confidenceScore }) }
        return keyed.values.sorted { lhs, rhs in
            switch (lhs.totalPrice, rhs.totalPrice) {
            case let (l?, r?):
                if l == r { return lhs.confidenceScore > rhs.confidenceScore }
                return l < r
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.confidenceScore > rhs.confidenceScore
            }
        }
    }

    private func deeplinkFallbackQuotes(query: FlightSearchQuery, now: Date) -> [FlightQuote] {
        [
            FlightQuote(
                id: "google::\(routeID(for: query))",
                providerName: "Google Flights",
                title: "\(query.origin.city) to \(query.destination.city)",
                totalPrice: nil,
                currencyCode: query.currencyCode,
                stopsText: "See live fares",
                durationText: "Flexible",
                summary: "Open the exact live fare matrix in Google Flights.",
                sourceURL: FlightScoutFormatting.googleFlightsURL(origin: query.origin.iataCode, destination: query.destination.iataCode, departureDate: query.departureDate, returnDate: query.returnDate),
                bookingURL: FlightScoutFormatting.googleFlightsURL(origin: query.origin.iataCode, destination: query.destination.iataCode, departureDate: query.departureDate, returnDate: query.returnDate),
                fetchedAt: now,
                confidenceScore: 50
            ),
            FlightQuote(
                id: "kayak::\(routeID(for: query))",
                providerName: "Kayak",
                title: "\(query.origin.city) to \(query.destination.city)",
                totalPrice: nil,
                currencyCode: query.currencyCode,
                stopsText: "Compare live",
                durationText: "Flexible",
                summary: "Open live compare fares on Kayak.",
                sourceURL: FlightScoutFormatting.kayakURL(origin: query.origin.iataCode, destination: query.destination.iataCode, departureDate: query.departureDate, returnDate: query.returnDate),
                bookingURL: FlightScoutFormatting.kayakURL(origin: query.origin.iataCode, destination: query.destination.iataCode, departureDate: query.departureDate, returnDate: query.returnDate),
                fetchedAt: now,
                confidenceScore: 45
            ),
            FlightQuote(
                id: "skyscanner::\(routeID(for: query))",
                providerName: "Skyscanner",
                title: "\(query.origin.city) to \(query.destination.city)",
                totalPrice: nil,
                currencyCode: query.currencyCode,
                stopsText: "Compare live",
                durationText: "Flexible",
                summary: "Open live compare fares on Skyscanner.",
                sourceURL: FlightScoutFormatting.skyscannerURL(origin: query.origin.iataCode, destination: query.destination.iataCode, departureDate: query.departureDate, returnDate: query.returnDate),
                bookingURL: FlightScoutFormatting.skyscannerURL(origin: query.origin.iataCode, destination: query.destination.iataCode, departureDate: query.departureDate, returnDate: query.returnDate),
                fetchedAt: now,
                confidenceScore: 44
            )
        ]
    }

    private func makePublicQuote(
        provider: String,
        result: DuckResult,
        query: FlightSearchQuery,
        now: Date
    ) async -> FlightQuote? {
        let snippetText = "\(result.title) \(result.snippet)"
        var price = Self.extractBestPrice(from: snippetText)
        var confidence = price != nil ? 80 : 55
        var summary = result.snippet.isEmpty ? "Open the live booking page." : result.snippet

        if let pageSnapshot = try? await fetchSourceSnapshot(from: result.url) {
            if price == nil {
                price = Self.extractBestPrice(from: pageSnapshot)
                if price != nil {
                    confidence = 88
                }
            } else {
                confidence = max(confidence, 84)
            }

            if let structuredSummary = Self.extractSummary(from: pageSnapshot), structuredSummary.isEmpty == false {
                summary = structuredSummary
            }
        }

        let bookingURL = providerBookingURL(provider: provider, query: query)
        return FlightQuote(
            id: "public::\(provider)::\(bookingURL.absoluteString)",
            providerName: provider,
            title: trimmedTitle(result.title, fallback: "\(query.origin.city) to \(query.destination.city)"),
            totalPrice: price?.amount,
            currencyCode: price?.currencyCode ?? query.currencyCode,
            stopsText: inferStopsText(from: summary),
            durationText: inferDurationText(from: summary),
            summary: summary,
            sourceURL: result.url,
            bookingURL: bookingURL,
            fetchedAt: now,
            confidenceScore: confidence
        )
    }

    private func searchDuckDuckGo(searchText: String) async throws -> [DuckResult] {
        var components = URLComponents(string: "https://html.duckduckgo.com/html/")!
        components.queryItems = [.init(name: "q", value: searchText)]
        let data = try await loadData(from: components.url!)
        guard let html = String(data: data, encoding: .utf8) else { return [] }
        return parseDuckResults(html: html)
    }

    private func parseDuckResults(html: String) -> [DuckResult] {
        let blockRegex = try? NSRegularExpression(pattern: "(?s)<div class=\\\"result results_links[^\\\"]*\\\">(.*?)</div>\\s*</div>")
        let linkRegex = try? NSRegularExpression(pattern: "<a[^>]*class=\\\"result__a\\\"[^>]*href=\\\"([^\\\"]+)\\\"[^>]*>(.*?)</a>")
        let snippetRegex = try? NSRegularExpression(pattern: "<a[^>]*class=\\\"result__snippet\\\"[^>]*>(.*?)</a>|<div[^>]*class=\\\"result__snippet\\\"[^>]*>(.*?)</div>")

        let nsHTML = html as NSString
        let blocks = blockRegex?.matches(in: html, range: NSRange(location: 0, length: nsHTML.length)) ?? []
        return blocks.compactMap { block in
            let blockText = nsHTML.substring(with: block.range(at: 1))
            let nsBlock = blockText as NSString
            guard let linkMatch = linkRegex?.firstMatch(in: blockText, range: NSRange(location: 0, length: nsBlock.length)) else {
                return nil
            }

            let href = htmlDecoded(nsBlock.substring(with: linkMatch.range(at: 1)))
            let title = strippedHTML(htmlDecoded(nsBlock.substring(with: linkMatch.range(at: 2))))

            let snippet: String
            if let snippetMatch = snippetRegex?.firstMatch(in: blockText, range: NSRange(location: 0, length: nsBlock.length)) {
                let chosenRange = snippetMatch.range(at: 1).location != NSNotFound ? snippetMatch.range(at: 1) : snippetMatch.range(at: 2)
                snippet = strippedHTML(htmlDecoded(nsBlock.substring(with: chosenRange)))
            } else {
                snippet = ""
            }

            guard let finalURL = normalizedDuckURL(href) else { return nil }
            return DuckResult(url: finalURL, title: title, snippet: snippet)
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

    private func fetchSourceSnapshot(from url: URL) async throws -> String {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            throw URLError(.unsupportedURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Mozilla/5.0 FlightScout", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeRawData)
        }
        return Self.pageSnapshot(fromHTML: html)
    }

    static func extractBestPrice(from text: String) -> (amount: Double, currencyCode: String)? {
        let patterns: [(String, String)] = [
            ("USD", "(?:US\\$|USD\\s*)([0-9][0-9,]{1,})"),
            ("SGD", "(?:S\\$|SGD\\s*)([0-9][0-9,]{1,})"),
            ("GBP", "(?:£|GBP\\s*)([0-9][0-9,]{1,})"),
            ("EUR", "(?:€|EUR\\s*)([0-9][0-9,]{1,})"),
            ("INR", "(?:₹|INR\\s*|Rs\\.?\\s*)([0-9][0-9,]{1,})"),
            ("AUD", "(?:A\\$|AUD\\s*)([0-9][0-9,]{1,})")
        ]

        var matches: [(amount: Double, currencyCode: String)] = []
        for (currency, pattern) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let nsText = text as NSString
            let found = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in found {
                guard let value = Double(nsText.substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: "")) else {
                    continue
                }
                guard value >= 40, value <= 15000 else { continue }
                matches.append((value, currency))
            }
        }

        if let best = matches.sorted(by: { lhs, rhs in
            if lhs.currencyCode == rhs.currencyCode {
                return lhs.amount < rhs.amount
            }
            return lhs.amount < rhs.amount
        }).first {
            return best
        }
        return nil
    }

    static func pageSnapshot(fromHTML html: String) -> String {
        let patterns = [
            "<meta[^>]+property=[\"']og:title[\"'][^>]+content=[\"']([^\"']+)[\"']",
            "<meta[^>]+property=[\"']og:description[\"'][^>]+content=[\"']([^\"']+)[\"']",
            "<meta[^>]+name=[\"']description[\"'][^>]+content=[\"']([^\"']+)[\"']",
            "<title[^>]*>(.*?)</title>"
        ]

        let extracted = patterns.compactMap { pattern in
            firstMatch(in: html, pattern: pattern)
        }

        let strippedBody = html
            .replacingOccurrences(of: "<script(?s).*?</script>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<style(?s).*?</style>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (extracted + [String(strippedBody.prefix(1200))]).joined(separator: " | ")
    }

    static func extractSummary(from snapshot: String) -> String? {
        let cleaned = snapshot
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { return nil }
        return String(cleaned.prefix(160))
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)), match.numberOfRanges > 1 else {
            return nil
        }
        return nsText.substring(with: match.range(at: 1))
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
    }

    private func inferStopsText(from text: String) -> String {
        let lowered = text.lowercased()
        if lowered.contains("direct") || lowered.contains("nonstop") {
            return "Direct"
        }
        if lowered.contains("1 stop") || lowered.contains("1-stop") {
            return "1 stop"
        }
        return "See route"
    }

    private func inferDurationText(from text: String) -> String {
        if let regex = try? NSRegularExpression(pattern: "([0-9]{1,2})\\s*h(?:\\s*([0-9]{1,2})\\s*m)?", options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length)) {
            return (text as NSString).substring(with: match.range(at: 0))
        }
        return "See duration"
    }

    private func trimmedTitle(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func routeID(for query: FlightSearchQuery) -> String {
        "\(query.origin.iataCode)-\(query.destination.iataCode)-\(query.departureDate.ISO8601Format())"
    }

    private func providerBookingURL(provider: String, query: FlightSearchQuery) -> URL {
        switch provider {
        case "Skyscanner":
            return FlightScoutFormatting.skyscannerURL(
                origin: query.origin.iataCode,
                destination: query.destination.iataCode,
                departureDate: query.departureDate,
                returnDate: query.returnDate
            )
        case "Kayak":
            return FlightScoutFormatting.kayakURL(
                origin: query.origin.iataCode,
                destination: query.destination.iataCode,
                departureDate: query.departureDate,
                returnDate: query.returnDate
            )
        default:
            return FlightScoutFormatting.googleFlightsURL(
                origin: query.origin.iataCode,
                destination: query.destination.iataCode,
                departureDate: query.departureDate,
                returnDate: query.returnDate
            )
        }
    }

    private func normalizedDuckURL(_ href: String) -> URL? {
        if let components = URLComponents(string: href),
           let encoded = components.queryItems?.first(where: { $0.name == "uddg" })?.value,
           let decoded = encoded.removingPercentEncoding,
           let url = URL(string: decoded) {
            return url
        }
        return URL(string: href)
    }

    private func htmlDecoded(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }

    private func strippedHTML(_ string: String) -> String {
        string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

private struct DuckResult: Sendable {
    let url: URL
    let title: String
    let snippet: String
}
