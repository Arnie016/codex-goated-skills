import AppKit
import Foundation

@MainActor
final class TradingArchiveBarAppModel: ObservableObject {
    @Published var sourcesText: String {
        didSet { persistPreferencesIfReady() }
    }
    @Published var storyLimit: Int {
        didSet {
            let clamped = max(10, min(80, storyLimit))
            if storyLimit != clamped {
                storyLimit = clamped
                return
            }
            persistPreferencesIfReady()
        }
    }
    @Published var query = ""
    @Published var window: TradingArchiveWindow {
        didSet { persistPreferencesIfReady() }
    }
    @Published private(set) var snapshot: TradingArchiveSnapshot
    @Published private(set) var loadState: TradingArchiveLoadState
    @Published private(set) var noteLine: String
    @Published var feedbackMessage: String?

    private let feedService: TradingArchiveFeedFetching
    private let store: TradingArchiveStoreProtocol
    private var favoriteIDs: Set<String>
    private var isHydrating = true
    private var clearFeedbackTask: Task<Void, Never>?

    init(
        feedService: TradingArchiveFeedFetching = LiveTradingArchiveFeedService(),
        store: TradingArchiveStoreProtocol = TradingArchiveUserDefaultsStore()
    ) {
        self.feedService = feedService
        self.store = store

        let preferences = store.loadPreferences() ?? TradingArchivePreferences(
            sourcesText: "",
            storyLimit: 24,
            window: .all
        )
        let initialSnapshot = store.loadSnapshot() ?? .empty
        self.sourcesText = preferences.sourcesText
        self.storyLimit = max(10, min(80, preferences.storyLimit))
        self.window = preferences.window
        self.snapshot = initialSnapshot
        self.favoriteIDs = Set(store.loadFavoriteIDs())
        self.loadState = initialSnapshot.articles.isEmpty ? .empty : .cached
        self.noteLine = initialSnapshot.articles.isEmpty
            ? "Add RSS or Atom feeds in Settings to build your trading reading archive."
            : "Loaded the saved archive while live feeds warm up."
        self.isHydrating = false
    }

    deinit {
        clearFeedbackTask?.cancel()
    }

    var menuBarTitle: String {
        "TA \(min(visibleArticles.count, 99))"
    }

    var menuBarSymbolName: String {
        switch loadState {
        case .live:
            return "chart.line.text.clipboard"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .cached:
            return "chart.line.text.clipboard.fill"
        case .error:
            return "exclamationmark.triangle"
        case .empty:
            return "newspaper"
        }
    }

    var parsedSourceURLs: [URL] {
        sourcesText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap(URL.init(string:))
            .filter { ["http", "https"].contains($0.scheme?.lowercased()) }
    }

    var visibleArticles: [TradingArchiveArticle] {
        let articles = snapshot.articles.filter(matchesSearch).filter(matchesWindow)
        return Array(articles.prefix(storyLimit))
    }

    var metricTiles: [TradingArchiveMetric] {
        [
            TradingArchiveMetric(
                id: "stored",
                title: "Archive",
                value: "\(snapshot.articles.count)",
                detail: "Saved articles"
            ),
            TradingArchiveMetric(
                id: "sources",
                title: "Sources",
                value: "\(snapshot.sourceStatuses.count)",
                detail: "Configured feeds"
            ),
            TradingArchiveMetric(
                id: "saved",
                title: "Saved",
                value: "\(favoriteIDs.count)",
                detail: "Starred reads"
            )
        ]
    }

    var sourceStatuses: [TradingArchiveSourceStatus] {
        snapshot.sourceStatuses
    }

    var dashboardLine: String {
        if parsedSourceURLs.isEmpty {
            return "No feeds configured yet. Paste RSS or Atom URLs into Settings to start archiving."
        }
        return "\(visibleArticles.count) visible now • \(snapshot.articles.count) stored • \(TradingArchiveFormatters.dashboardTimestamp(for: snapshot.capturedAt))"
    }

    func refreshIfNeeded() async {
        if snapshot.articles.isEmpty {
            await refresh(force: true)
        }
    }

    func refresh(force: Bool = false) async {
        let feedURLs = parsedSourceURLs
        guard !feedURLs.isEmpty else {
            snapshot = .empty
            loadState = .empty
            noteLine = "Add RSS or Atom feed URLs in Settings to build a local archive."
            persistPreferencesIfReady()
            return
        }

        if !force, loadState == .live, !snapshot.articles.isEmpty {
            return
        }

        loadState = .syncing
        noteLine = "Refreshing \(feedURLs.count) trading feeds."

        do {
            let freshSnapshot = try await feedService.fetch(from: feedURLs)
            snapshot = freshSnapshot
            store.saveSnapshot(freshSnapshot)
            loadState = freshSnapshot.articles.isEmpty ? .empty : .live
            noteLine = freshSnapshot.articles.isEmpty
                ? "The feeds responded, but no archiveable articles were found."
                : "Archive refreshed from live feeds."
            persistPreferencesIfReady()
        } catch {
            if let cached = store.loadSnapshot(), !cached.articles.isEmpty {
                snapshot = cached
                loadState = .cached
                noteLine = "Live refresh failed, so the menu bar is showing the saved archive."
            } else {
                loadState = .error
                noteLine = error.localizedDescription
            }
        }
    }

    func copyReadingQueue() {
        let lines = visibleArticles.map { article in
            "\(article.title) — \(article.sourceName) — \(article.publishedLabel)\n\(article.articleURL?.absoluteString ?? "")"
        }
        let content = lines.isEmpty ? "No visible articles in the current trading archive view." : lines.joined(separator: "\n\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        showFeedback("Reading queue copied.")
    }

    func toggleFavorite(_ article: TradingArchiveArticle) {
        if favoriteIDs.contains(article.id) {
            favoriteIDs.remove(article.id)
        } else {
            favoriteIDs.insert(article.id)
        }
        store.saveFavoriteIDs(Array(favoriteIDs).sorted())
    }

    func isFavorite(_ article: TradingArchiveArticle) -> Bool {
        favoriteIDs.contains(article.id)
    }

    func openArticle(_ article: TradingArchiveArticle) {
        guard let url = article.articleURL else { return }
        NSWorkspace.shared.open(url)
    }

    func openSource(_ source: TradingArchiveSourceStatus) {
        guard let url = URL(string: source.urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    private func matchesSearch(_ article: TradingArchiveArticle) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let haystack = [
            article.title,
            article.summary,
            article.sourceName,
            article.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        return haystack.contains(trimmed.lowercased())
    }

    private func matchesWindow(_ article: TradingArchiveArticle) -> Bool {
        switch window {
        case .all:
            return true
        case .favorites:
            return favoriteIDs.contains(article.id)
        case .today:
            guard let publishedAt = article.publishedAt else { return false }
            return Calendar.current.isDateInToday(publishedAt)
        case .week:
            guard let publishedAt = article.publishedAt else { return false }
            return publishedAt >= Date().addingTimeInterval(-(60 * 60 * 24 * 7))
        }
    }

    private func persistPreferencesIfReady() {
        guard !isHydrating else { return }
        store.savePreferences(
            TradingArchivePreferences(
                sourcesText: sourcesText,
                storyLimit: storyLimit,
                window: window
            )
        )
    }

    private func showFeedback(_ message: String) {
        feedbackMessage = message
        clearFeedbackTask?.cancel()
        clearFeedbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.feedbackMessage = nil
        }
    }
}
