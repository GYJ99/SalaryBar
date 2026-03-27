import Foundation

@MainActor
final class AppStorageStore {
    static let shared = AppStorageStore()

    private enum Keys {
        static let settings = "money_monitor.settings"
        static let runtime = "money_monitor.runtime"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSettings() -> AppSettings {
        guard let data = defaults.data(forKey: Keys.settings),
              let decoded = try? decoder.decode(AppSettings.self, from: data) else {
            return .default
        }
        return decoded
    }

    func save(settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else {
            return
        }
        defaults.set(data, forKey: Keys.settings)
    }

    func loadRuntime(calendar: Calendar = .current) -> RuntimeState {
        guard let data = defaults.data(forKey: Keys.runtime),
              let decoded = try? decoder.decode(RuntimeState.self, from: data) else {
            return .default(calendar: calendar)
        }
        return decoded
    }

    func save(runtime: RuntimeState) {
        guard let data = try? encoder.encode(runtime) else {
            return
        }
        defaults.set(data, forKey: Keys.runtime)
    }
}
