
import Foundation

protocol FavoriteStorageServiceProtocol {

    func isFavorite(username: String) -> Bool

    func addFavorite(username: String)

    func removeFavorite(username: String)

    func getFavorites() -> [String]

    func getRecentFavorites(limit: Int) -> [String]
}

final class FavoriteStorageService: FavoriteStorageServiceProtocol {

    private let defaults: UserDefaults

    private let storageKey = "favorite_usernames"
    private let recentStorageKey = "recent_favorite_usernames"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isFavorite(username: String) -> Bool {
        getFavorites().contains(username)
    }

    func addFavorite(username: String) {
        var favorites = getFavorites()

        guard !favorites.contains(username) else { return }

        favorites.append(username)

        defaults.set(
            favorites.sorted(),
            forKey: storageKey
        )

        var recent = getOrderedFavorites()
        recent.removeAll { $0 == username }
        recent.insert(username, at: 0)

        defaults.set(recent, forKey: recentStorageKey)
    }

    func removeFavorite(username: String) {
        var favorites = getFavorites()
        favorites.removeAll { $0 == username }

        defaults.set(
            favorites.sorted(),
            forKey: storageKey
        )

        var recent = getOrderedFavorites()
        recent.removeAll { $0 == username }

        defaults.set(recent, forKey: recentStorageKey)
    }

    func getFavorites() -> [String] {
        defaults.stringArray(forKey: storageKey) ?? []
    }

    func getRecentFavorites(limit: Int) -> [String] {
        guard limit > 0 else { return [] }

        return Array(getOrderedFavorites().prefix(limit))
    }

    private func getOrderedFavorites() -> [String] {
        let favorites = getFavorites()
        let stored = defaults.stringArray(forKey: recentStorageKey) ?? []

        let ordered = stored.filter { favorites.contains($0) }
        let missing = favorites.filter { !ordered.contains($0) }

        return ordered + missing
    }
}
