import XCTest
@testable import TradingArchiveBar

final class TradingArchiveBarTests: XCTestCase {
    func testParseRSSItems() throws {
        let xml = """
        <rss version="2.0">
          <channel>
            <title>Macro Desk</title>
            <item>
              <title>Rates setup into CPI</title>
              <link>https://example.com/rates-cpi</link>
              <description>Why duration traders are leaning cautious.</description>
              <pubDate>Fri, 28 Mar 2026 08:30:00 +0800</pubDate>
              <category>Rates</category>
            </item>
            <item>
              <title>FX reversal watchlist</title>
              <link>https://example.com/fx-reversal</link>
              <description>Dollar pairs worth tracking this week.</description>
              <pubDate>Thu, 27 Mar 2026 17:00:00 +0800</pubDate>
              <category>FX</category>
            </item>
          </channel>
        </rss>
        """

        let parsed = try LiveTradingArchiveFeedService.parseFeed(
            data: Data(xml.utf8),
            sourceURL: URL(string: "https://example.com/feed.xml")!
        )

        XCTAssertEqual(parsed.sourceTitle, "Macro Desk")
        XCTAssertEqual(parsed.articles.count, 2)
        XCTAssertEqual(parsed.articles.first?.title, "Rates setup into CPI")
        XCTAssertEqual(parsed.articles.first?.tags, ["Rates"])
    }

    @MainActor
    func testRefreshUsesCachedSnapshotWhenFetchFails() async {
        let cached = TradingArchiveSnapshot(
            capturedAt: Date(),
            articles: [
                TradingArchiveArticle(
                    id: "cached",
                    title: "Cached article",
                    summary: "Still visible",
                    sourceName: "Archive",
                    sourceURL: URL(string: "https://example.com/feed.xml"),
                    articleURL: URL(string: "https://example.com/cached"),
                    publishedAt: Date(),
                    tags: ["Macro"]
                )
            ],
            sourceStatuses: []
        )

        let store = TradingArchiveMemoryStore(snapshot: cached)
        let model = TradingArchiveBarAppModel(
            feedService: TradingArchiveFailingFeedService(),
            store: store
        )
        model.sourcesText = "https://example.com/feed.xml"

        await model.refresh(force: true)

        XCTAssertEqual(model.loadState, .cached)
        XCTAssertEqual(model.visibleArticles.first?.title, "Cached article")
    }

    @MainActor
    func testVisibleArticlesRespectSearchWindowAndFavorites() {
        let now = Date()
        let weekOld = now.addingTimeInterval(-(60 * 60 * 24 * 8))
        let snapshot = TradingArchiveSnapshot(
            capturedAt: now,
            articles: [
                TradingArchiveArticle(
                    id: "a",
                    title: "Momentum setup",
                    summary: "Breakout notes",
                    sourceName: "Desk",
                    sourceURL: nil,
                    articleURL: nil,
                    publishedAt: now,
                    tags: ["Momentum"]
                ),
                TradingArchiveArticle(
                    id: "b",
                    title: "Old commodity read",
                    summary: "Oil desk archive",
                    sourceName: "Desk",
                    sourceURL: nil,
                    articleURL: nil,
                    publishedAt: weekOld,
                    tags: ["Commodities"]
                )
            ],
            sourceStatuses: []
        )

        let store = TradingArchiveMemoryStore(snapshot: snapshot, favorites: ["b"])
        let model = TradingArchiveBarAppModel(
            feedService: TradingArchiveFailingFeedService(),
            store: store
        )

        model.query = "momentum"
        XCTAssertEqual(model.visibleArticles.map(\.id), ["a"])

        model.query = ""
        model.window = .favorites
        XCTAssertEqual(model.visibleArticles.map(\.id), ["b"])

        model.window = .today
        XCTAssertEqual(model.visibleArticles.map(\.id), ["a"])
    }
}

private struct TradingArchiveFailingFeedService: TradingArchiveFeedFetching {
    func fetch(from feedURLs: [URL]) async throws -> TradingArchiveSnapshot {
        throw URLError(.badServerResponse)
    }
}

private struct TradingArchiveMemoryStore: TradingArchiveStoreProtocol {
    var snapshot: TradingArchiveSnapshot?
    var preferences: TradingArchivePreferences?
    var favorites: [String] = []

    init(snapshot: TradingArchiveSnapshot? = nil, preferences: TradingArchivePreferences? = nil, favorites: [String] = []) {
        self.snapshot = snapshot
        self.preferences = preferences
        self.favorites = favorites
    }

    func loadSnapshot() -> TradingArchiveSnapshot? { snapshot }
    func saveSnapshot(_ snapshot: TradingArchiveSnapshot) {}
    func loadPreferences() -> TradingArchivePreferences? { preferences }
    func savePreferences(_ preferences: TradingArchivePreferences) {}
    func loadFavoriteIDs() -> [String] { favorites }
    func saveFavoriteIDs(_ ids: [String]) {}
}
