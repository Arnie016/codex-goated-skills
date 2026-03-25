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
        _ = pack.insert(text: "Stack trace line 1", sourceAppName: "Terminal")
        _ = pack.insert(text: "let currentStep = .capture", sourceAppName: "Cursor")

        let formatted = ContextPackFormatter.format(objective: "", pack: pack)

        let cursorRange = formatted.range(of: "## Context 1 • Cursor")
        let terminalRange = formatted.range(of: "## Context 2 • Terminal")

        XCTAssertNotNil(cursorRange)
        XCTAssertNotNil(terminalRange)
        XCTAssertTrue(cursorRange!.lowerBound < terminalRange!.lowerBound)
        XCTAssertTrue(formatted.contains("```\nlet currentStep = .capture\n```"))
        XCTAssertTrue(formatted.contains("```\nStack trace line 1\n```"))
    }
}
