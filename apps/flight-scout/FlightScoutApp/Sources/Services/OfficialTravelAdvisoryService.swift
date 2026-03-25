import Foundation

actor OfficialTravelAdvisoryService {
    private struct CacheEntry: Sendable {
        let advisories: [String: OfficialTravelAdvisory]
        let fetchedAt: Date
    }

    private let session: URLSession
    private var cacheEntry: CacheEntry?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func advisory(for destination: FlightPlace, now: Date = Date()) async -> OfficialTravelAdvisory? {
        let advisories = await advisories(now: now)
        for key in candidateKeys(for: destination) {
            if let advisory = advisories[key] {
                return advisory
            }
        }
        return nil
    }

    private func advisories(now: Date) async -> [String: OfficialTravelAdvisory] {
        if let cacheEntry, now.timeIntervalSince(cacheEntry.fetchedAt) < 6 * 60 * 60 {
            return cacheEntry.advisories
        }

        guard let url = URL(string: "https://travel.state.gov/content/travel/en/traveladvisories/traveladvisories.html") else {
            return cacheEntry?.advisories ?? [:]
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return cacheEntry?.advisories ?? [:]
            }
            guard let html = String(data: data, encoding: .utf8) else {
                return cacheEntry?.advisories ?? [:]
            }

            let advisories = Self.parse(html: html)
            cacheEntry = CacheEntry(advisories: advisories, fetchedAt: now)
            return advisories
        } catch {
            return cacheEntry?.advisories ?? [:]
        }
    }

    private func candidateKeys(for destination: FlightPlace) -> [String] {
        let inputs = [
            destination.countryName,
            destination.city,
            destination.airportName
        ] + destination.aliases

        var seen = Set<String>()
        return inputs.compactMap { value in
            let key = Self.normalizedKey(for: value)
            guard seen.insert(key).inserted else { return nil }
            return key
        }
    }

    static func parse(html: String) -> [String: OfficialTravelAdvisory] {
        let pattern = #"""
        (?s)<tr>\s*<th[^>]*>\s*<a\s+href="([^"]+)"[^>]*>(.*?)</a>\s*</th>\s*<td><p><span class="level-badge level-badge-([1-4])"></span>\s*(Level\s+[1-4]:\s*[^<]+)</p></td>\s*<td>\s*(.*?)\s*</td>\s*<td><p>([^<]+)</p></td>\s*</tr>
        """#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [:]
        }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        var advisories: [String: OfficialTravelAdvisory] = [:]
        for match in matches {
            guard
                let hrefRange = Range(match.range(at: 1), in: html),
                let nameRange = Range(match.range(at: 2), in: html),
                let levelRange = Range(match.range(at: 3), in: html),
                let summaryRange = Range(match.range(at: 4), in: html),
                let reasonRange = Range(match.range(at: 5), in: html),
                let updatedRange = Range(match.range(at: 6), in: html),
                let levelValue = Int(html[levelRange]),
                let level = TravelAdvisoryLevel(rawValue: levelValue)
            else {
                continue
            }

            let rawName = Self.strippedHTML(String(html[nameRange]))
            let key = normalizedKey(for: rawName)
            guard !key.isEmpty else { continue }

            let href = String(html[hrefRange])
            let sourceURL = URL(string: href.hasPrefix("http") ? href : "https://travel.state.gov\(href)") ?? URL(string: "https://travel.state.gov/content/travel/en/traveladvisories/traveladvisories.html")!
            let summary = Self.strippedHTML(String(html[summaryRange]))
            let reasonsHTML = String(html[reasonRange])
            let reasons = Self.parseReasons(from: reasonsHTML)
            let lastUpdated = Self.parseDate(Self.strippedHTML(String(html[updatedRange])))

            advisories[key] = OfficialTravelAdvisory(
                authorityName: "US",
                level: level,
                summary: summary,
                reasons: reasons,
                sourceURL: sourceURL,
                lastUpdated: lastUpdated
            )
        }

        return advisories
    }

    private static func parseReasons(from html: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"<span class="tsg-utility-risk-pill">(.*?)</span>"#) else {
            return []
        }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))
        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let value = nsHTML.substring(with: match.range(at: 1))
            let trimmed = strippedHTML(value)
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatters: [DateFormatter] = {
            let formats = ["MM/dd/yyyy", "MMMM d, yyyy"]
            return formats.map { format in
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.dateFormat = format
                return formatter
            }
        }()

        for formatter in formatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    private static func strippedHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedKey(for value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "&", with: " and ")
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
