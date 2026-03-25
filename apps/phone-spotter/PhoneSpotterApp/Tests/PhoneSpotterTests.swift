import XCTest
@testable import PhoneSpotter

final class PhoneSpotterTests: XCTestCase {
    func testPlatformTitlesStayStable() {
        XCTAssertEqual(PhonePlatform.iphone.title, "iPhone")
        XCTAssertEqual(PhonePlatform.android.providerTitle, "Google Find")
    }

    func testStateRoundTripKeepsEntries() throws {
        let state = PhoneSpotterState(
            profile: PhoneSpotterProfile(hasCompletedSetup: true, deviceName: "Pixel", platform: .android, integrationMode: .webPortal, phoneNumber: "+123456", allowRing: true, allowCall: true, allowManualNotes: true),
            snapshot: PhoneSpotterSnapshot(lastSeenLabel: "Office desk", latitude: 1.23, longitude: 4.56, ipAddress: "192.168.1.8", lastUsedNote: "Using Maps", lastUsedAt: .distantPast, providerStatus: "Ready"),
            entries: [PhoneSpotterLogEntry(title: "Locate Requested", detail: "Opened the provider flow.", kind: .locate)]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(state)
        let decoded = try decoder.decode(PhoneSpotterState.self, from: data)

        XCTAssertEqual(decoded.profile.deviceName, "Pixel")
        XCTAssertTrue(decoded.profile.hasCompletedSetup)
        XCTAssertEqual(decoded.snapshot.ipAddress, "192.168.1.8")
        XCTAssertEqual(decoded.entries.first?.kind, .locate)
    }
}
