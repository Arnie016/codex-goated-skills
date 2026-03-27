import AppKit
import Foundation

@MainActor
final class OnThisDayBarAppModel: ObservableObject {
    @Published var activeKind: OnThisDayFeedKind {
        didSet { persistPreferencesIfReady() }
    }
    @Published var storyLimit: Int {
        didSet {
            let clamped = max(3, min(7, storyLimit))
            if storyLimit != clamped {
                storyLimit = clamped
                return
            }
            persistPreferencesIfReady()
        }
    }
    @Published private(set) var selectedDate: Date
    @Published private(set) var snapshot: OnThisDaySnapshot?
    @Published private(set) var loadState: OnThisDayLoadState
    @Published private(set) var noteLine: String
    @Published var feedbackMessage: String?

    private let feedService: OnThisDayFeedFetching
    private let store: OnThisDayStoreProtocol
    private let timeZone: TimeZone
    private var isHydrating = true
    private var clearFeedbackTask: Task<Void, Never>?

    init(
        feedService: OnThisDayFeedFetching = LiveOnThisDayFeedService(),
        store: OnThisDayStoreProtocol = OnThisDayUserDefaultsStore(),
        timeZone: TimeZone = OnThisDayDateSupport.singaporeTimeZone,
        autoRefresh: Bool = true
    ) {
        self.feedService = feedService
        self.store = store
        self.timeZone = timeZone

        let preferences = store.loadPreferences() ?? OnThisDayPreferences(dateKey: nil, activeKind: .selected, storyLimit: 5)
        let initialDate = OnThisDayDateSupport.date(from: preferences.dateKey ?? "", timeZone: timeZone) ?? OnThisDayDateSupport.today(timeZone: timeZone)
        let initialSnapshot = store.loadSnapshot(for: OnThisDayDateSupport.dateKey(for: initialDate, timeZone: timeZone))
        self.activeKind = preferences.activeKind
        self.storyLimit = max(3, min(7, preferences.storyLimit))
        self.selectedDate = initialDate
        self.snapshot = initialSnapshot
        self.loadState = initialSnapshot == nil ? .syncing : .cached
        self.noteLine = initialSnapshot == nil ? "Pulling the official archive for this day." : "Showing your saved snapshot while the live feed warms up."
        self.isHydrating = false

        if autoRefresh {
            Task { [weak self] in
                await self?.refresh(force: initialSnapshot == nil)
            }
        }
    }

    deinit {
        clearFeedbackTask?.cancel()
    }

    var displayedKind: OnThisDayFeedKind {
        if activeKind == .selected, snapshot?.selected.isEmpty == true, snapshot?.events.isEmpty == false {
            return .events
        }
        return activeKind
    }

    var visibleEntries: [OnThisDayEntry] {
        Array((snapshot?.entries(for: displayedKind) ?? []).prefix(storyLimit))
    }

    var spotlightEntry: OnThisDayEntry? {
        visibleEntries.first
    }

    var dateTitle: String {
        OnThisDayDateSupport.displayTitle(for: selectedDate, timeZone: timeZone)
    }

    var menuBarTitle: String {
        OnThisDayDateSupport.shortLabel(for: selectedDate, timeZone: timeZone)
    }

    var menuBarSymbolName: String {
        switch loadState {
        case .error:
            return "calendar.badge.exclamationmark"
        case .cached:
            return "calendar.badge.clock"
        case .live:
            return "calendar.badge.checkmark"
        case .syncing:
            return "calendar"
        }
    }

    var summaryLine: String {
        let counts = [
            "\(count(for: .selected)) curated picks",
            "\(count(for: .events)) raw events",
            "\(count(for: .holidays)) observances"
        ]
        return "\(displayedKind.title) view for \(OnThisDayDateSupport.monthDay(for: selectedDate, timeZone: timeZone)), spanning \(yearSpanText). \(counts.joined(separator: ", "))."
    }

    var storySummary: String {
        if visibleEntries.isEmpty {
            return noteLine
        }
        let noun = visibleEntries.count == 1 ? "entry" : "entries"
        return "\(visibleEntries.count) \(noun) • \(yearSpanText) • \(loadState.title.lowercased())"
    }

    var metricTiles: [OnThisDayMetric] {
        [
            OnThisDayMetric(title: "Visible now", value: "\(visibleEntries.count)", detail: "\(displayedKind.title) entries"),
            OnThisDayMetric(title: "Year span", value: yearSpanText, detail: numericYearCount > 0 ? "Across this slice" : "Non-numeric archive view"),
            OnThisDayMetric(title: "Feed mode", value: loadState.title, detail: "Official Wikimedia source")
        ]
    }

    var yearSpanText: String {
        let years = visibleEntries.compactMap(\.numericYear).sorted()
        guard let first = years.first, let last = years.last else {
            return displayedKind == .holidays ? "Observance window" : "Open archive"
        }
        return first == last ? "\(first)" : "\(first)-\(last)"
    }

    var numericYearCount: Int {
        visibleEntries.compactMap(\.numericYear).count
    }

    func count(for kind: OnThisDayFeedKind) -> Int {
        snapshot?.count(for: kind) ?? 0
    }

    func refreshIfNeeded() async {
        let dateKey = OnThisDayDateSupport.dateKey(for: selectedDate, timeZone: timeZone)
        if snapshot?.dateKey == dateKey, loadState != .error {
            return
        }
        await refresh(force: snapshot == nil)
    }

    func refresh(force: Bool = false) async {
        let dateKey = OnThisDayDateSupport.dateKey(for: selectedDate, timeZone: timeZone)
        if !force, snapshot?.dateKey == dateKey, loadState != .error {
            return
        }

        loadState = .syncing
        noteLine = "Refreshing the official archive for \(OnThisDayDateSupport.monthDay(for: selectedDate, timeZone: timeZone))."

        do {
            let freshSnapshot = try await feedService.fetch(date: selectedDate, timeZone: timeZone)
            snapshot = freshSnapshot
            store.saveSnapshot(freshSnapshot)
            loadState = .live
            noteLine = "Updated from Wikimedia for \(OnThisDayDateSupport.monthDay(for: selectedDate, timeZone: timeZone))."
            persistPreferencesIfReady()
        } catch {
            if let cachedSnapshot = store.loadSnapshot(for: dateKey) {
                snapshot = cachedSnapshot
                loadState = .cached
                noteLine = "Live fetch failed, so the popover is using the last saved snapshot for this day."
            } else {
                loadState = .error
                noteLine = error.localizedDescription
            }
        }
    }

    func jumpToday() {
        selectedDate = OnThisDayDateSupport.today(timeZone: timeZone)
        persistPreferencesIfReady()
        Task { await refresh(force: true) }
    }

    func moveDate(by days: Int) {
        selectedDate = OnThisDayDateSupport.shifted(date: selectedDate, byDays: days, timeZone: timeZone)
        persistPreferencesIfReady()
        Task { await refresh(force: true) }
    }

    func randomizeDay() {
        selectedDate = OnThisDayDateSupport.randomDate(timeZone: timeZone)
        persistPreferencesIfReady()
        Task { await refresh(force: true) }
    }

    func copyDigest() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(buildDigest(), forType: .string)
        showFeedback("Daily brief copied.")
    }

    func openLead() {
        guard let url = spotlightEntry?.articleURL else {
            openDocs()
            return
        }
        NSWorkspace.shared.open(url)
    }

    func openEntry(_ entry: OnThisDayEntry) {
        guard let url = entry.articleURL else {
            openDocs()
            return
        }
        NSWorkspace.shared.open(url)
    }

    func openDocs() {
        guard let url = URL(string: "https://api.wikimedia.org/wiki/Feed_API/Reference/On_this_day") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func setKind(_ kind: OnThisDayFeedKind) {
        activeKind = kind
    }

    private func buildDigest() -> String {
        var lines = [
            "On This Day · \(dateTitle)",
            "\(displayedKind.title) · \(loadState.title)",
            ""
        ]

        for entry in visibleEntries {
            lines.append("- \(entry.yearLabel) — \(entry.text)")
            if let url = entry.articleURL {
                lines.append("  \(url.absoluteString)")
            }
        }

        lines.append("")
        lines.append("Source API: https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/all/\(monthAndDayPath())")
        lines.append("Official docs: https://api.wikimedia.org/wiki/Feed_API/Reference/On_this_day")
        return lines.joined(separator: "\n")
    }

    private func monthAndDayPath() -> String {
        let calendar = OnThisDayDateSupport.calendar(timeZone: timeZone)
        let components = calendar.dateComponents([.month, .day], from: selectedDate)
        let month = String(format: "%02d", components.month ?? 1)
        let day = String(format: "%02d", components.day ?? 1)
        return "\(month)/\(day)"
    }

    private func showFeedback(_ message: String) {
        feedbackMessage = message
        clearFeedbackTask?.cancel()
        clearFeedbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            self?.feedbackMessage = nil
        }
    }

    private func persistPreferencesIfReady() {
        guard !isHydrating else {
            return
        }

        let preferences = OnThisDayPreferences(
            dateKey: OnThisDayDateSupport.dateKey(for: selectedDate, timeZone: timeZone),
            activeKind: activeKind,
            storyLimit: storyLimit
        )
        store.savePreferences(preferences)
    }
}
