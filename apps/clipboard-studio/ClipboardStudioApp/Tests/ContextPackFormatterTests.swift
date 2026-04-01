import XCTest
@testable import ClipboardStudio

final class ContextPackFormatterTests: XCTestCase {
    func testFormatterIncludesObjectiveWhenPresent() {
        var pack = ContextPack()
        _ = pack.insert(text: "func shipFeature() {}", sourceAppName: "Xcode")

        let formatted = ContextPackFormatter.format(
            objective: "Help me explain why this function is failing.",
            pack: pack
        )

        XCTAssertTrue(formatted.contains("## Objective"))
        XCTAssertTrue(formatted.contains("Help me explain why this function is failing."))
    }

    func testFormatterUsesNewestFirstWithSourceLabelsAndFences() {
        var pack = ContextPack()
        _ = pack.insert(
            text: "Stack trace line 1",
            sourceAppName: "Terminal",
            capturedAt: Date(timeIntervalSince1970: 10)
        )
        _ = pack.insert(
            text: "let currentStep = .capture",
            sourceAppName: "Cursor",
            capturedAt: Date(timeIntervalSince1970: 20)
        )

        let formatted = ContextPackFormatter.format(objective: "", pack: pack)

        let timelineRange = formatted.range(of: "## Timeline")
        let cursorRange = formatted.range(of: "## Context 1 • From Cursor")
        let terminalRange = formatted.range(of: "## Context 2 • From Terminal")

        XCTAssertNotNil(timelineRange)
        XCTAssertNotNil(cursorRange)
        XCTAssertNotNil(terminalRange)
        XCTAssertTrue(cursorRange!.lowerBound < terminalRange!.lowerBound)
        XCTAssertTrue(formatted.contains("1. Terminal"))
        XCTAssertTrue(formatted.contains("2. Cursor"))
        XCTAssertTrue(formatted.contains("Timeline Step: 2"))
        XCTAssertTrue(formatted.contains("Timeline Step: 1"))
        XCTAssertTrue(formatted.contains("```\nlet currentStep = .capture\n```"))
        XCTAssertTrue(formatted.contains("```\nStack trace line 1\n```"))
    }

    func testExportDocumentIncludesTitleTimestampAndSources() {
        var pack = ContextPack()
        _ = pack.insert(text: "docs say to retry after refreshing token", sourceAppName: "Chrome")
        _ = pack.insert(text: "error: unauthorized", sourceAppName: "Terminal")

        let exportedAt = Date(timeIntervalSince1970: 1_710_000_000)
        let document = ContextPackFormatter.formatExportDocument(
            title: "Fix login issue",
            objective: "Explain the failure and next fix.",
            pack: pack,
            exportedAt: exportedAt
        )

        XCTAssertTrue(document.hasPrefix("# Fix login issue"))
        XCTAssertTrue(document.contains("Exported from Context Assembly on"))
        XCTAssertTrue(document.contains("Sources: Terminal, Chrome"))
        XCTAssertTrue(document.contains("## Objective"))
        XCTAssertTrue(document.contains("## Timeline"))
        XCTAssertTrue(document.contains("## Context 1 • From Terminal"))
    }
}
