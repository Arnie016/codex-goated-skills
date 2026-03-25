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
}
