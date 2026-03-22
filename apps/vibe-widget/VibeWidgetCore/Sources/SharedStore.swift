import Foundation

public final class SharedStore: @unchecked Sendable {
    public static let shared = SharedStore()

    private enum Keys {
        static let snapshot = "widget.snapshot"
        static let settings = "app.settings"
        static let pendingActions = "widget.pending-actions"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults? = nil) {
        if let defaults {
            self.defaults = defaults
        } else if let suite = UserDefaults(suiteName: VibeAppGroup.identifier) {
            self.defaults = suite
        } else {
            self.defaults = .standard
        }

        encoder.outputFormatting = [.sortedKeys]
    }

    public func loadSnapshot() -> WidgetSnapshot {
        decode(WidgetSnapshot.self, forKey: Keys.snapshot) ?? WidgetSnapshot()
    }

    public func saveSnapshot(_ snapshot: WidgetSnapshot) {
        encode(snapshot, forKey: Keys.snapshot)
    }

    public func loadSettings() -> AppSettings {
        decode(AppSettings.self, forKey: Keys.settings) ?? AppSettings()
    }

    public func saveSettings(_ settings: AppSettings) {
        encode(settings, forKey: Keys.settings)
    }

    public func enqueue(action: QueuedWidgetAction) {
        var actions = decode([QueuedWidgetAction].self, forKey: Keys.pendingActions) ?? []
        actions.append(action)
        encode(actions, forKey: Keys.pendingActions)
    }

    public func dequeueAllActions() -> [QueuedWidgetAction] {
        let actions = decode([QueuedWidgetAction].self, forKey: Keys.pendingActions) ?? []
        defaults.removeObject(forKey: Keys.pendingActions)
        return actions
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
