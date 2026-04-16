import Foundation
import XCTest
@testable import OnThisDayBar

@MainActor
final class OnThisDayBarTests: XCTestCase {
    func testSelectedFallbackUsesEventsWhenNeeded() {
        let snapshot = makeSnapshot(
            dateKey: "2026-03-27",
            selected: [],
            events: [makeEntry(year: 2015, title: "Himeji Castle")]
        )
        let store = MemoryStore(
            preferences: OnThisDayPreferences(dateKey: snapshot.dateKey, activeKind: .selected, storyLimit: 5),
            snapshots: [snapshot.dateKey: snapshot]
        )
        let model = OnThisDayBarAppModel(
            feedService: MockFeedService(result: .success(snapshot)),
            store: store,
            autoRefresh: false
        )

        XCTAssertEqual(model.displayedKind, .events)
        XCTAssertEqual(model.visibleEntries.first?.title, "Himeji Castle")
    }

    func testRefreshUsesCachedSnapshotWhenLiveFetchFails() async {
        let snapshot = makeSnapshot(
            dateKey: "2026-03-27",
            selected: [makeEntry(year: 2023, title: "Ciudad Juarez migrant center fire")]
        )
        let store = MemoryStore(
            preferences: OnThisDayPreferences(dateKey: snapshot.dateKey, activeKind: .selected, storyLimit: 5),
            snapshots: [snapshot.dateKey: snapshot]
        )
        let model = OnThisDayBarAppModel(
            feedService: MockFeedService(result: .failure(URLError(.notConnectedToInternet))),
            store: store,
            autoRefresh: false
        )

        await model.refresh(force: true)

        XCTAssertEqual(model.loadState, .cached)
        XCTAssertEqual(model.visibleEntries.first?.title, "Ciudad Juarez migrant center fire")
    }

    func testYearSpanReflectsVisibleEntries() {
        let snapshot = makeSnapshot(
            dateKey: "2026-03-27",
            selected: [
                makeEntry(year: 1999, title: "NATO bombing of Yugoslavia"),
                makeEntry(year: 2023, title: "Ciudad Juarez migrant center fire")
            ]
        )
        let store = MemoryStore(
            preferences: OnThisDayPreferences(dateKey: snapshot.dateKey, activeKind: .selected, storyLimit: 5),
            snapshots: [snapshot.dateKey: snapshot]
        )
        let model = OnThisDayBarAppModel(
            feedService: MockFeedService(result: .success(snapshot)),
            store: store,
            autoRefresh: false
        )

        XCTAssertEqual(model.yearSpanText, "1999-2023")
    }

    private func makeSnapshot(
        dateKey: String,
        selected: [OnThisDayEntry] = [],
        events: [OnThisDayEntry] = [],
        births: [OnThisDayEntry] = [],
        deaths: [OnThisDayEntry] = [],
        holidays: [OnThisDayEntry] = []
    ) -> OnThisDaySnapshot {
        OnThisDaySnapshot(
            dateKey: dateKey,
            capturedAt: .distantPast,
            selected: selected,
            events: events,
            births: births,
            deaths: deaths,
            holidays: holidays
        )
    }

    private func makeEntry(year: Int, title: String) -> OnThisDayEntry {
        OnThisDayEntry(
            id: "\(year)-\(title)",
            yearLabel: "\(year)",
            numericYear: year,
            title: title,
            text: "\(title) happened on this day.",
            detail: "Sample detail",
            pageTags: [title],
            articleURL: URL(string: "https://example.com/\(year)"),
            imageURL: nil
        )
    }
}

private final class MemoryStore: OnThisDayStoreProtocol {
    var preferences: OnThisDayPreferences?
    var snapshots: [String: OnThisDaySnapshot]

    init(preferences: OnThisDayPreferences?, snapshots: [String: OnThisDaySnapshot]) {
        self.preferences = preferences
        self.snapshots = snapshots
    }

    func loadPreferences() -> OnThisDayPreferences? {
        preferences
    }

    func savePreferences(_ preferences: OnThisDayPreferences) {
        self.preferences = preferences
    }

    func loadSnapshot(for dateKey: String) -> OnThisDaySnapshot? {
        snapshots[dateKey]
    }

    func saveSnapshot(_ snapshot: OnThisDaySnapshot) {
        snapshots[snapshot.dateKey] = snapshot
    }
}

private struct MockFeedService: OnThisDayFeedFetching {
    let result: Result<OnThisDaySnapshot, Error>

    func fetch(date: Date, timeZone: TimeZone) async throws -> OnThisDaySnapshot {
        try result.get()
    }
}
