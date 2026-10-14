
import Foundation

protocol FavoriteStorageServiceProtocol {
    func isFavorite(username: String) -> Bool
    func addFavorite(username: String)
    func removeFavorite(username: String)
    func getFavorites() -> [String]
}

final class FavoriteStorageService: FavoriteStorageServiceProtocol {

    private let defaults: UserDefaults
    private let storageKey = "favorite_usernames"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isFavorite(username: String) -> Bool {
        return getFavorites().contains(username)
    }

    func addFavorite(username: String) {
        var favorites = Set(getFavorites())
        favorites.insert(username)

        defaults.set(
            Array(favorites).sorted(),
            forKey: storageKey
        )
    }

    func removeFavorite(username: String) {
        var favorites = Set(getFavorites())
        favorites.remove(username)

        defaults.set(
            Array(favorites).sorted(),
            forKey: storageKey
        )
    }

    func getFavorites() -> [String] {
        return defaults.stringArray(
            forKey: storageKey
        ) ?? []
    }
}
  
