import XCTest
import VibeWidgetCore

final class ContextLibraryTests: XCTestCase {
    func testTokenEstimateUsesCharacterHeuristicAndWordFloor() {
        let metrics = ContextTextMetrics.estimate(for: "SwiftUI panels make local RAG feel snappy.")

        XCTAssertEqual(metrics.wordCount, 7)
        XCTAssertEqual(metrics.estimatedTokenCount, 11)
        XCTAssertEqual(metrics.estimatedChunkCount, 1)
    }

    func testChunkEstimateRoundsUp() {
        let metrics = ContextTextMetrics.estimate(for: String(repeating: "a", count: 4_100), chunkSize: 800)

        XCTAssertEqual(metrics.estimatedTokenCount, 1_025)
        XCTAssertEqual(metrics.estimatedChunkCount, 2)
    }
}
