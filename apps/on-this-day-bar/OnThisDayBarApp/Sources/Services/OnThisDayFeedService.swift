import Foundation

protocol OnThisDayFeedFetching: Sendable {
    func fetch(date: Date, timeZone: TimeZone) async throws -> OnThisDaySnapshot
}

enum OnThisDayFeedServiceError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The Wikimedia feed response was invalid."
        case .httpStatus(let status):
            return "Wikimedia returned HTTP \(status)."
        }
    }
}

struct LiveOnThisDayFeedService: OnThisDayFeedFetching, Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(date: Date, timeZone: TimeZone) async throws -> OnThisDaySnapshot {
        let dateKey = OnThisDayDateSupport.dateKey(for: date, timeZone: timeZone)
        let url = try endpointURL(for: date, timeZone: timeZone)
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "codex-goated-skills/on-this-day-bar (https://github.com/Arnie016/codex-goated-skills)",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OnThisDayFeedServiceError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw OnThisDayFeedServiceError.httpStatus(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let payload = try decoder.decode(FeedPayload.self, from: data)
        return OnThisDaySnapshot(
            dateKey: dateKey,
            capturedAt: Date(),
            selected: map(payload.selected, fallbackKind: .selected),
            events: map(payload.events, fallbackKind: .events),
            births: map(payload.births, fallbackKind: .births),
            deaths: map(payload.deaths, fallbackKind: .deaths),
            holidays: map(payload.holidays, fallbackKind: .holidays)
        )
    }

    private func endpointURL(for date: Date, timeZone: TimeZone) throws -> URL {
        let calendar = OnThisDayDateSupport.calendar(timeZone: timeZone)
        let components = calendar.dateComponents([.month, .day], from: date)
        let month = String(format: "%02d", components.month ?? 1)
        let day = String(format: "%02d", components.day ?? 1)
        guard let url = URL(string: "https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/all/\(month)/\(day)") else {
            throw OnThisDayFeedServiceError.invalidResponse
        }
        return url
    }

    private func map(_ items: [FeedItem], fallbackKind: OnThisDayFeedKind) -> [OnThisDayEntry] {
        items.map { item in
            let primaryPage = preferredPage(from: item.pages)
            let fallbackTitle = item.text.split(separator: ".").first.map(String.init) ?? fallbackKind.title
            let resolvedTitle = primaryPage?.titles?.normalized
                ?? primaryPage?.normalizedtitle
                ?? primaryPage?.displaytitle
                ?? primaryPage?.title
                ?? fallbackTitle
            let title = cleaned(resolvedTitle)
            let detail = cleaned(primaryPage?.description ?? "Linked from the official Wikimedia day feed.")
            let pageTags = pageTagsForPages(item.pages)
            let yearLabel = item.year.map(String.init) ?? (fallbackKind == .holidays ? "Holiday" : "Archive")
            let articleURL = primaryPage?.content_urls?.desktop?.page ?? primaryPage?.content_urls?.mobile?.page
            let imageURL = primaryPage?.thumbnail?.source

            return OnThisDayEntry(
                id: "\(yearLabel)-\(title)-\(cleaned(item.text))",
                yearLabel: yearLabel,
                numericYear: item.year,
                title: title,
                text: cleaned(item.text),
                detail: detail,
                pageTags: pageTags,
                articleURL: articleURL,
                imageURL: imageURL
            )
        }
    }

    private func preferredPage(from pages: [FeedPage]) -> FeedPage? {
        pages.first(where: { $0.content_urls?.desktop?.page != nil }) ??
        pages.first(where: { $0.thumbnail?.source != nil }) ??
        pages.first
    }

    private func pageTagsForPages(_ pages: [FeedPage]) -> [String] {
        Array(
            pages
                .compactMap { page in
                    let resolved = page.titles?.normalized
                        ?? page.normalizedtitle
                        ?? page.displaytitle
                        ?? page.title
                    let cleanedValue = cleaned(resolved ?? "")
                    return cleanedValue.isEmpty ? nil : cleanedValue
                }
                .prefix(3)
        )
    }

    private func cleaned(_ value: String) -> String {
        value
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .split(whereSeparator: \.isNewline)
            .joined(separator: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}

private struct FeedPayload: Decodable {
    let selected: [FeedItem]
    let events: [FeedItem]
    let births: [FeedItem]
    let deaths: [FeedItem]
    let holidays: [FeedItem]
}

private struct FeedItem: Decodable {
    let text: String
    let year: Int?
    let pages: [FeedPage]
}

private struct FeedPage: Decodable {
    let title: String?
    let normalizedtitle: String?
    let displaytitle: String?
    let description: String?
    let thumbnail: FeedThumbnail?
    let content_urls: FeedContentURLs?
    let titles: FeedTitles?
}

private struct FeedTitles: Decodable {
    let normalized: String?
}

private struct FeedThumbnail: Decodable {
    let source: URL?
}

private struct FeedContentURLs: Decodable {
    let desktop: FeedPageURLs?
    let mobile: FeedPageURLs?
}

private struct FeedPageURLs: Decodable {
    let page: URL?
}
