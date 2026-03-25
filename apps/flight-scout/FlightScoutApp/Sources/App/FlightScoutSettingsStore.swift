import Foundation

actor FlightScoutSettingsStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let settingsKey = "flightscout.settings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.outputFormatting = [.sortedKeys]
    }

    func load() -> FlightScoutSettings {
        guard let data = defaults.data(forKey: settingsKey) else {
            return FlightScoutSettings()
        }
        return (try? decoder.decode(FlightScoutSettings.self, from: data)) ?? FlightScoutSettings()
    }

    func save(_ settings: FlightScoutSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }
}
