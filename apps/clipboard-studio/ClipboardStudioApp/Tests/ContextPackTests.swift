import XCTest
@testable import ClipboardStudio

final class ContextPackTests: XCTestCase {
    func testDuplicateSelectionDoesNotCreateDuplicatePackItem() {
        var pack = ContextPack()

        let firstInsert = pack.insert(text: "let answer = 42", sourceAppName: "Xcode")
        let secondInsert = pack.insert(text: "let answer = 42", sourceAppName: "Xcode")

        XCTAssertEqual(pack.items.count, 1)

        if case .added = firstInsert {
        } else {
            XCTFail("Expected the first insert to add a new pack item.")
        }

        if case .duplicate = secondInsert {
        } else {
            XCTFail("Expected the second insert to detect a duplicate.")
        }
    }

    func testRemoveAndClearUpdatePackDeterministically() {
        var pack = ContextPack()
        let first = pack.insert(text: "first clip", sourceAppName: "Cursor")
        let second = pack.insert(text: "second clip", sourceAppName: "Terminal")

        guard case let .added(firstItem) = first else {
            return XCTFail("Expected the first insert to succeed.")
        }
        guard case .added = second else {
            return XCTFail("Expected the second insert to succeed.")
        }

        let removed = pack.remove(id: firstItem.id)
        XCTAssertEqual(removed?.text, "first clip")
        XCTAssertEqual(pack.items.count, 1)
        XCTAssertEqual(pack.items.first?.text, "second clip")

        pack.clear()
        XCTAssertTrue(pack.items.isEmpty)
    }

    func testHistoryStoreAndPackRemainSeparate() {
        var history = ClipboardHistoryStore()
        var pack = ContextPack()

        _ = history.record(text: "error: missing semicolon", sourceAppName: "Terminal", limit: 60)
        _ = pack.insert(text: "struct BuildState {}", sourceAppName: "Xcode")

        XCTAssertEqual(history.entries.count, 1)
        XCTAssertEqual(history.entries.first?.text, "error: missing semicolon")
        XCTAssertEqual(pack.items.count, 1)
        XCTAssertEqual(pack.items.first?.text, "struct BuildState {}")
    }

    func testTimelineItemsPreserveCaptureOrder() {
        var pack = ContextPack()
        _ = pack.insert(
            text: "first capture",
            sourceAppName: "Terminal",
            capturedAt: Date(timeIntervalSince1970: 10)
        )
        _ = pack.insert(
            text: "second capture",
            sourceAppName: "Xcode",
            capturedAt: Date(timeIntervalSince1970: 20)
        )
        _ = pack.insert(
            text: "third capture",
            sourceAppName: "Chrome",
            capturedAt: Date(timeIntervalSince1970: 30)
        )

        XCTAssertEqual(pack.timelineItems.map(\.text), ["first capture", "second capture", "third capture"])
        XCTAssertEqual(pack.timelineStep(for: pack.timelineItems[0].id), 1)
        XCTAssertEqual(pack.timelineStep(for: pack.timelineItems[2].id), 3)
    }

    func testFocusHistoryDeduplicatesByStateSignature() {
        var history = FocusHistoryStore()

        let first = FocusSnapshot(
            appName: "Google Chrome",
            bundleIdentifier: "com.google.Chrome",
            pageTitle: "hotdogs in new york - Google Search",
            urlString: "https://www.google.com/search?q=hotdogs+in+new+york",
            selectedText: "best hotdogs in new york"
        )
        let second = FocusSnapshot(
            appName: "Google Chrome",
            bundleIdentifier: "com.google.Chrome",
            pageTitle: "hotdogs in new york - Google Search",
            urlString: "https://www.google.com/search?q=hotdogs+in+new+york",
            selectedText: "best hotdogs in new york"
        )

        let storedFirst = history.record(snapshot: first, limit: 10)
        let storedSecond = history.record(snapshot: second, limit: 10)

        XCTAssertEqual(history.items.count, 1)
        XCTAssertEqual(storedFirst.id, storedSecond.id)
        XCTAssertEqual(history.items.first?.pageTitle, "hotdogs in new york - Google Search")
    }

    func testFocusSnapshotAssemblyTextIncludesSourceAndSelection() {
        let snapshot = FocusSnapshot(
            appName: "Microsoft Word",
            bundleIdentifier: "com.microsoft.Word",
            windowTitle: "Essay Draft",
            selectedText: "This is the highlighted paragraph."
        )

        XCTAssertTrue(snapshot.assemblyText.contains("Source App: Microsoft Word"))
        XCTAssertTrue(snapshot.assemblyText.contains("Window Title: Essay Draft"))
        XCTAssertTrue(snapshot.assemblyText.contains("Selected Text:"))
        XCTAssertTrue(snapshot.assemblyText.contains("This is the highlighted paragraph."))
    }
}
