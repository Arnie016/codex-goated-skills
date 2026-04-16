import XCTest
@testable import ClipboardStudio

final class ContextAssemblyExportServiceTests: XCTestCase {
    func testSuggestedTitleUsesObjectiveWhenPresent() {
        var pack = ContextPack()
        _ = pack.insert(text: "research notes", sourceAppName: "Terminal")

        let objective = String(repeating: "A", count: 80)
        let title = ContextAssemblyExportService.suggestedTitle(
            objective: objective,
            pack: pack,
            exportedAt: Date(timeIntervalSince1970: 1_710_000_000)
        )

        XCTAssertEqual(title, String(objective.prefix(72)))
    }

    func testSuggestedTitleFallsBackToSourceAppNameWhenObjectiveIsEmpty() {
        var pack = ContextPack()
        _ = pack.insert(text: "clipboard item", sourceAppName: "Cursor")

        let title = ContextAssemblyExportService.suggestedTitle(
            objective: "   ",
            pack: pack,
            exportedAt: Date(timeIntervalSince1970: 1_710_000_000)
        )

        XCTAssertEqual(title, "Context Assembly from Cursor")
    }

    func testExportMarkdownWritesSluggedDocument() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let document = "# Fix login issue\n\nThis is the exported assembly."
        let fileURL = try ContextAssemblyExportService.exportMarkdown(
            document: document,
            title: "Fix login issue!",
            to: tempDirectory,
            exportedAt: Date(timeIntervalSince1970: 1_710_000_000)
        )

        XCTAssertTrue(fileURL.lastPathComponent.hasPrefix("fix-login-issue-"))
        XCTAssertTrue(fileURL.lastPathComponent.hasSuffix(".md"))
        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8), document)
    }
}
