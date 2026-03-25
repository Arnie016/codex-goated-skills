import Foundation
import XCTest
@testable import FlightScout

final class FlightScoutTests: XCTestCase {
    func testRegionParserReadsIPInfoPayload() throws {
        let data = Data(
            """
            {
              "ip": "119.234.160.16",
              "city": "Singapore",
              "region": "Singapore",
              "country": "SG",
              "loc": "1.2897,103.8501",
              "timezone": "Asia/Singapore"
            }
            """.utf8
        )

        let region = try VPNRegionService.parseRegion(data: data)

        XCTAssertEqual(region.countryCode, "SG")
        XCTAssertEqual(region.city, "Singapore")
        XCTAssertEqual(region.timezone, "Asia/Singapore")
        XCTAssertEqual(try XCTUnwrap(region.latitude), 1.2897, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(region.longitude), 103.8501, accuracy: 0.0001)
    }

    func testSourceCatalogCoverageHasAtLeastOneHundredUniqueDefinitions() {
        let sources = FlightScoutSourceCatalog.allSources
        let categories = Set(sources.map(\.category))

        XCTAssertGreaterThanOrEqual(sources.count, 100)
        XCTAssertEqual(Set(sources.map(\.id)).count, sources.count)
        XCTAssertEqual(categories, Set(FlightRiskCategory.allCases))
        XCTAssertGreaterThan(FlightScoutSourceCatalog.sources(for: .essential).count, 10)
        XCTAssertGreaterThan(FlightScoutSourceCatalog.sources(for: .full).count, FlightScoutSourceCatalog.sources(for: .essential).count)
    }

    func testRouteResolverMatchesVPNOriginAndCountryAliases() throws {
        let resolver = FlightRouteResolverService()
        let region = VPNRegion(
            ipAddress: "",
            city: "Singapore",
            regionName: "Singapore",
            countryCode: "SG",
            countryName: "Singapore",
            timezone: "Asia/Singapore",
            latitude: 1.29,
            longitude: 103.85
        )

        let origin = resolver.resolveOrigin(for: region)
        let brazil = try XCTUnwrap(resolver.resolveDestination(query: "Brazil"))
        let london = try XCTUnwrap(resolver.resolveDestination(query: "London"))

        XCTAssertEqual(origin.iataCode, "SIN")
        XCTAssertEqual(brazil.countryCode, "BR")
        XCTAssertEqual(london.iataCode, "LHR")
    }

    func testDeterministicRankingPrefersLowerRiskAndLowerPrice() async {
        let ranking = FlightScoutRankingService()
        let now = Date(timeIntervalSince1970: 1_710_000_000)

        let lowRisk = makeRoute(
            id: "london",
            price: 620,
            destination: "London",
            riskScore: 24,
            riskLevel: .guarded,
            now: now
        )
        let highRisk = makeRoute(
            id: "brazil",
            price: 580,
            destination: "Sao Paulo",
            riskScore: 78,
            riskLevel: .high,
            now: now
        )
        let cheaperAndSafer = makeRoute(
            id: "mumbai",
            price: 310,
            destination: "Mumbai",
            riskScore: 32,
            riskLevel: .guarded,
            now: now
        )

        let ranked = await ranking.deterministicRank([lowRisk, highRisk, cheaperAndSafer])

        XCTAssertEqual(ranked.first?.id, "mumbai")
        XCTAssertEqual(ranked.last?.id, "brazil")
        XCTAssertEqual(ranked.first?.rankingMode, .deterministicFallback)
    }

    func testPersistenceStoreExportsMarkdownCSVAndJSON() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let store = FlightScoutPersistenceStore(rootDirectory: tempDirectory)
        let saved = [SavedFlightOpportunity(opportunity: makeRoute(id: "saved", price: 540, destination: "London", riskScore: 21, riskLevel: .guarded, now: Date()))]

        let artifacts = try await store.exportDigest(routes: saved, title: "flight-scout-test")

        XCTAssertEqual(Set(artifacts.map(\.kind)), Set([.markdown, .csv, .json]))
        for artifact in artifacts {
            XCTAssertTrue(FileManager.default.fileExists(atPath: artifact.fileURL.path))
        }

        let markdownURL = try XCTUnwrap(artifacts.first(where: { $0.kind == .markdown })?.fileURL)
        let markdown = try String(contentsOf: markdownURL, encoding: .utf8)
        XCTAssertTrue(markdown.contains("flight-scout-test"))
        XCTAssertTrue(markdown.contains("London"))
    }

    func testOfficialTravelAdvisoryParserReadsCountryLevelAndReasons() throws {
        let html = """
        <tbody>
            <tr>
                <th scope="row"><a href="https://travel.state.gov/content/travel/en/international-travel/International-Travel-Country-Information-Pages/UnitedKingdom.html" target="_blank">United Kingdom</a></th>
                <td><p><span class="level-badge level-badge-2"></span>Level 2: Exercise increased caution</p></td>
                <td>
                    <div class="tsg-utility-risk-pill-container">
                        <span class="tsg-utility-risk-pill">TERRORISM (T)</span>
                        <span class="tsg-utility-risk-pill">CIVIL UNREST (U)</span>
                    </div>
                </td>
                <td><p>03/24/2026</p></td>
            </tr>
        </tbody>
        """

        let parsed = OfficialTravelAdvisoryService.parse(html: html)
        let advisory = try XCTUnwrap(parsed[OfficialTravelAdvisoryService.normalizedKey(for: "United Kingdom")])

        XCTAssertEqual(advisory.level, .level2)
        XCTAssertEqual(advisory.summary, "Level 2: Exercise increased caution")
        XCTAssertEqual(advisory.reasons, ["TERRORISM (T)", "CIVIL UNREST (U)"])
        XCTAssertEqual(advisory.compactLabel, "US L2")
    }

    func testSafetyEvaluatorRejectsRouteWithHighOfficialAdvisory() {
        let safer = makeRoute(
            id: "safer",
            price: 650,
            destination: "London",
            riskScore: 24,
            riskLevel: .guarded,
            advisory: OfficialTravelAdvisory(
                authorityName: "US",
                level: .level1,
                summary: "Level 1: Exercise normal precautions",
                reasons: [],
                sourceURL: URL(string: "https://example.com/advisory/l1")!,
                lastUpdated: nil
            ),
            now: Date(timeIntervalSince1970: 1_710_000_000)
        )

        let unsafe = makeRoute(
            id: "unsafe",
            price: 600,
            destination: "Sao Paulo",
            riskScore: 30,
            riskLevel: .guarded,
            advisory: OfficialTravelAdvisory(
                authorityName: "US",
                level: .level3,
                summary: "Level 3: Reconsider travel",
                reasons: [],
                sourceURL: URL(string: "https://example.com/advisory/l3")!,
                lastUpdated: nil
            ),
            now: Date(timeIntervalSince1970: 1_710_000_000)
        )

        XCTAssertTrue(FlightSafetyEvaluator.qualifies(safer))
        XCTAssertFalse(FlightSafetyEvaluator.qualifies(unsafe))
        XCTAssertEqual(FlightSafetyEvaluator.badgeText(for: safer), "Safer pick")
        XCTAssertEqual(FlightSafetyEvaluator.badgeText(for: unsafe), "Review risk")
    }

    func testPublicPriceExtractionPrefersRealWebPagePriceText() {
        let html = """
        <html>
            <head>
                <title>Singapore to London flights from £791 | Example Travel</title>
                <meta name="description" content="Compare Singapore to London return flights from £791 on live booking pages.">
            </head>
            <body>
                <div>Best round-trip fare from £791 for Apr 8 - Apr 15.</div>
            </body>
        </html>
        """

        let snapshot = FlightPriceSearchService.pageSnapshot(fromHTML: html)
        let price = FlightPriceSearchService.extractBestPrice(from: snapshot)

        XCTAssertEqual(price?.currencyCode, "GBP")
        XCTAssertEqual(price?.amount, 791)
        XCTAssertTrue(snapshot.contains("Singapore to London flights from £791"))
    }
}

private func makeRoute(
    id: String,
    price: Double,
    destination: String,
    riskScore: Int,
    riskLevel: TravelRiskLevel,
    advisory: OfficialTravelAdvisory? = nil,
    now: Date
) -> FlightRouteOpportunity {
    let origin = FlightPlace(
        id: "SIN",
        iataCode: "SIN",
        city: "Singapore",
        countryCode: "SG",
        countryName: "Singapore",
        airportName: "Singapore Changi Airport",
        latitude: 1.36,
        longitude: 103.99,
        aliases: ["singapore"]
    )
    let place = FlightPlace(
        id: destination,
        iataCode: String(destination.prefix(3)).uppercased(),
        city: destination,
        countryCode: destination == "Sao Paulo" ? "BR" : "GB",
        countryName: destination == "Sao Paulo" ? "Brazil" : "United Kingdom",
        airportName: "\(destination) International Airport",
        latitude: nil,
        longitude: nil,
        aliases: [destination.lowercased()]
    )
    let quote = FlightQuote(
        id: "\(id)-quote",
        providerName: "Google Flights",
        title: "Route",
        totalPrice: price,
        currencyCode: "USD",
        stopsText: "Direct",
        durationText: "12h 0m",
        summary: "Live route",
        sourceURL: URL(string: "https://example.com/source")!,
        bookingURL: URL(string: "https://example.com/book")!,
        fetchedAt: now,
        confidenceScore: 90
    )

    return FlightRouteOpportunity(
        id: id,
        origin: origin,
        destination: place,
        queryText: destination,
        quotes: [quote],
        bestQuote: quote,
        patternSignals: [FlightPatternSignal(label: "Cheapest now", summary: "Good live fare")],
        travelRisk: TravelRiskSnapshot(
            score: riskScore,
            level: riskLevel,
            summary: "Risk summary",
            breakdown: .zero,
            officialAdvisory: advisory,
            weatherSummary: nil,
            headlines: [],
            rankingMode: .deterministicFallback,
            lastUpdated: now
        ),
        rankingScore: 0,
        rankingMode: .deterministicFallback,
        firstSeenAt: now,
        fetchedAt: now,
        isNew: true
    )
}
