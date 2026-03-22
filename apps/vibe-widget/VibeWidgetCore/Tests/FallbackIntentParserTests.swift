import XCTest
import VibeWidgetCore

final class FallbackIntentParserTests: XCTestCase {
    func testDimBedroomAndRainParsesBothDomains() {
        let plan = FallbackIntentParser.parse("dim bedroom lights and play rain sounds")
        XCTAssertEqual(plan.room, "Bedroom")
        XCTAssertEqual(plan.light.action, .dim)
        XCTAssertEqual(plan.music.action, .rain)
        XCTAssertFalse(plan.needsConfirmation)
    }

    func testJustinBieberButNotHimExtractsArtistAndExclusion() {
        let plan = FallbackIntentParser.parse("play something cool like Justin Bieber but not him")
        XCTAssertTrue(plan.seedArtists.contains("Justin Bieber"))
        XCTAssertTrue(plan.excludedArtists.contains("him"))
        XCTAssertEqual(plan.music.action, .play)
    }

    func testNewArtistsBecomesRecommendationIntent() {
        let plan = FallbackIntentParser.parse("play new artists")
        XCTAssertEqual(plan.music.action, .recommend)
        XCTAssertTrue(plan.moodTags.contains("fresh"))
    }
}
