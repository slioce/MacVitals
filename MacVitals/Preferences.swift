import Foundation

enum Preferences {
    enum Key {
        static let showsMemory = "showsMemory"
        static let showsSwap = "showsSwap"
        static let showsCPU = "showsCPU"
        static let refreshInterval = "refreshInterval"
    }

    /// Choices offered for the refresh interval, in seconds.
    static let intervals: [TimeInterval] = [2, 5, 10]

    static func register() {
        UserDefaults.standard.register(defaults: [
            Key.showsMemory: true,
            Key.showsSwap: true,
            Key.showsCPU: false,
            Key.refreshInterval: 5.0,
        ])
    }

    static func bool(_ key: String) -> Bool { UserDefaults.standard.bool(forKey: key) }

    static func toggle(_ key: String) { UserDefaults.standard.set(!bool(key), forKey: key) }

    static var refreshInterval: TimeInterval {
        get { max(1, UserDefaults.standard.double(forKey: Key.refreshInterval)) }
        set { UserDefaults.standard.set(newValue, forKey: Key.refreshInterval) }
    }
}
