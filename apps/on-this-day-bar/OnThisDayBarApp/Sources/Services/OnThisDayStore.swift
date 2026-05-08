import Foundation

protocol OnThisDayStoreProtocol: AnyObject {
    func loadPreferences() -> OnThisDayPreferences?
    func savePreferences(_ preferences: OnThisDayPreferences)
    func loadSnapshot(for dateKey: String) -> OnThisDaySnapshot?
    func saveSnapshot(_ snapshot: OnThisDaySnapshot)
}

final class OnThisDayUserDefaultsStore: OnThisDayStoreProtocol {
    private enum Keys {
        static let preferences = "OnThisDayBar.preferences"

        static func snapshot(_ dateKey: String) -> String {
            "OnThisDayBar.snapshot.\(dateKey)"
        }
    }

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func loadPreferences() -> OnThisDayPreferences? {
        guard let data = defaults.data(forKey: Keys.preferences) else {
            return nil
        }

        return try? decoder.decode(OnThisDayPreferences.self, from: data)
    }

    func savePreferences(_ preferences: OnThisDayPreferences) {
        guard let data = try? encoder.encode(preferences) else {
            return
        }

        defaults.set(data, forKey: Keys.preferences)
    }

    func loadSnapshot(for dateKey: String) -> OnThisDaySnapshot? {
        guard let data = defaults.data(forKey: Keys.snapshot(dateKey)) else {
            return nil
        }

        return try? decoder.decode(OnThisDaySnapshot.self, from: data)
    }

    func saveSnapshot(_ snapshot: OnThisDaySnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: Keys.snapshot(snapshot.dateKey))
    }
}
