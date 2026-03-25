import Foundation

enum PhonePlatform: String, Codable, CaseIterable, Identifiable, Sendable {
    case iphone
    case android

    var id: String { rawValue }

    var title: String {
        switch self {
        case .iphone:
            return "iPhone"
        case .android:
            return "Android"
        }
    }

    var providerTitle: String {
        switch self {
        case .iphone:
            return "Apple Find My"
        case .android:
            return "Google Find"
        }
    }

    var symbolName: String {
        switch self {
        case .iphone:
            return "iphone.gen3.radiowaves.left.and.right"
        case .android:
            return "smartphone"
        }
    }
}

enum IntegrationMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case nativeApp
    case webPortal
    case guidedCompanion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nativeApp:
            return "Native App"
        case .webPortal:
            return "Web Portal"
        case .guidedCompanion:
            return "Companion Ready"
        }
    }

    var subtitle: String {
        switch self {
        case .nativeApp:
            return "Fastest handoff into the platform app on this Mac."
        case .webPortal:
            return "Uses the signed-in web flow for locate and ring actions."
        case .guidedCompanion:
            return "Leaves room for richer permission-based telemetry later."
        }
    }
}

enum PhoneActionKind: String, Codable, Sendable {
    case locate
    case ring
    case call
    case directions
    case openProvider
    case remember
    case copySummary
}

struct PhoneSpotterProfile: Codable, Equatable, Sendable {
    var hasCompletedSetup: Bool = false
    var deviceName: String = "My Phone"
    var platform: PhonePlatform = .iphone
    var integrationMode: IntegrationMode = .nativeApp
    var phoneNumber: String = ""
    var allowRing: Bool = true
    var allowCall: Bool = true
    var allowManualNotes: Bool = true
}

struct PhoneSpotterSnapshot: Codable, Equatable, Sendable {
    var lastSeenLabel: String = "No provider location captured yet."
    var latitude: Double?
    var longitude: Double?
    var ipAddress: String = ""
    var lastUsedNote: String = "Add the last thing you remember doing with your phone."
    var lastUsedAt: Date?
    var providerStatus: String = "Waiting for your preferred provider flow."
    var pinnedClues: [String] = []
    var savedPlaces: [String] = ["Home", "Office", "Car", "Gym"]
}

struct PhoneSpotterLogEntry: Codable, Identifiable, Equatable, Sendable {
    var id: UUID = UUID()
    var timestamp: Date = .now
    var title: String
    var detail: String
    var kind: PhoneActionKind
}

struct PhoneSpotterState: Codable, Equatable, Sendable {
    var profile: PhoneSpotterProfile = .init()
    var snapshot: PhoneSpotterSnapshot = .init()
    var entries: [PhoneSpotterLogEntry] = []
}
