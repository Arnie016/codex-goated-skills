import XCTest
@testable import WifiWatchtower

final class WifiTrustScorerTests: XCTestCase {
    func testAssessNetworkMarksOpenWiFiAsAvoid() {
        let scorer = WifiTrustScorer()
        let current = ParsedCurrentNetwork(
            name: "Cafe Wi-Fi",
            security: "Open",
            channel: "11 (2GHz, 20MHz)",
            phyMode: "802.11n",
            signal: -82,
            noise: -92,
            txRate: 54
        )

        let assessment = scorer.assessNetwork(
            current: current,
            connectionKind: nil,
            gateway: "192.168.1.1",
            dnsServers: ["1.1.1.1"],
            captivePortal: false,
            nearbyNetworks: [
                NearbyNetwork(
                    name: "Guest",
                    security: "WPA2 Personal",
                    channel: "6 (2GHz, 20MHz)",
                    type: "Infrastructure",
                    signal: -70,
                    band: "2.4 GHz",
                    riskProbability: 38,
                    estimatedDistance: "~10-20 m"
                )
            ]
        )

        XCTAssertEqual(assessment.trustLevel, .avoid)
        XCTAssertEqual(assessment.guidanceTitle, "Not fine for sensitive use")
        XCTAssertTrue(assessment.issues.contains { $0.title == "Open network" })
    }

    func testAssessNetworkRewardsStrongHotspotAndHelpersClassifySignals() {
        let scorer = WifiTrustScorer()
        let current = ParsedCurrentNetwork(
            name: "Personal Hotspot",
            security: "WPA3 Personal",
            channel: "44 (5GHz, 80MHz)",
            phyMode: "802.11ax",
            signal: -45,
            noise: -92,
            txRate: 480
        )
        let nearbyNetworks = [
            NearbyNetwork(
                name: "Neighbor",
                security: "WPA2 Personal",
                channel: "6 (2GHz, 20MHz)",
                type: "Infrastructure",
                signal: -70,
                band: "2.4 GHz",
                riskProbability: 38,
                estimatedDistance: "~10-20 m"
            )
        ]

        let assessment = scorer.assessNetwork(
            current: current,
            connectionKind: "iPhone hotspot",
            gateway: "192.168.1.1",
            dnsServers: ["1.1.1.1", "8.8.8.8"],
            captivePortal: false,
            nearbyNetworks: nearbyNetworks
        )

        XCTAssertEqual(assessment.trustLevel, .safe)
        XCTAssertEqual(assessment.guidanceTitle, "Fine for normal use")
        XCTAssertEqual(scorer.bandLabel(from: current.channel), "5 GHz")
        XCTAssertEqual(scorer.estimatedDistance(from: current.signal), "~1-3 m")
        XCTAssertEqual(scorer.confidenceScore(current: current, gateway: "192.168.1.1", dnsServers: ["1.1.1.1", "8.8.8.8"], nearbyNetworks: nearbyNetworks), 100)
        XCTAssertLessThan(
            scorer.riskProbability(security: current.security, channel: current.channel, signal: current.signal),
            scorer.riskProbability(security: "Open", channel: "11 (2GHz, 20MHz)", signal: -82)
        )
    }
}
