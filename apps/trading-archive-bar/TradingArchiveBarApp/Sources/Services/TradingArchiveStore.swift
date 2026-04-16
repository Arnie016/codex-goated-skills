import Foundation

protocol TradingArchiveStoreProtocol {
    func loadSnapshot() -> TradingArchiveSnapshot?
    func saveSnapshot(_ snapshot: TradingArchiveSnapshot)
    func loadPreferences() -> TradingArchivePreferences?
    func savePreferences(_ preferences: TradingArchivePreferences)
    func loadFavoriteIDs() -> [String]
    func saveFavoriteIDs(_ ids: [String])
}

struct TradingArchiveUserDefaultsStore: TradingArchiveStoreProtocol {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadSnapshot() -> TradingArchiveSnapshot? {
        guard let data = defaults.data(forKey: Keys.snapshot),
              let snapshot = try? decoder.decode(TradingArchiveSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }

    func saveSnapshot(_ snapshot: TradingArchiveSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: Keys.snapshot)
    }

    func loadPreferences() -> TradingArchivePreferences? {
        guard let data = defaults.data(forKey: Keys.preferences),
              let preferences = try? decoder.decode(TradingArchivePreferences.self, from: data) else {
            return nil
        }
        return preferences
    }

    func savePreferences(_ preferences: TradingArchivePreferences) {
        guard let data = try? encoder.encode(preferences) else { return }
        defaults.set(data, forKey: Keys.preferences)
    }

    func loadFavoriteIDs() -> [String] {
        defaults.stringArray(forKey: Keys.favorites) ?? []
    }

    func saveFavoriteIDs(_ ids: [String]) {
        defaults.set(ids, forKey: Keys.favorites)
    }

    private enum Keys {
        static let snapshot = "trading-archive.snapshot"
        static let preferences = "trading-archive.preferences"
        static let favorites = "trading-archive.favorites"
    }
}
