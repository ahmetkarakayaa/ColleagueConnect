import Foundation
enum FavoritesSortOption {
    case newest
    case oldest
    case alphabetical
    case reverseAlphabetical
}

@MainActor
protocol FavoritesViewInput: AnyObject {
    func displayFavorites(_ users: [FavoriteUserViewModel])
    func displayLoading()
    func displayEmpty()
    func displayNoResults()
    func displayError(_ message: String)
}

@MainActor
protocol FavoritesViewOutput: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func filterFavorites(query: String)
    func removeFavorite(username: String)
    func didSelectUser(_ user: FavoriteUserViewModel)
    func sortFavorites(by option: FavoritesSortOption)
    func retryFavorites()
}

protocol FavoritesInteractorInput {
    func getFavorites() -> [String]
    func removeFavorite(username: String)
    func fetchFavoriteUser(username: String) async throws -> FavoriteUserProfile
}

@MainActor
protocol FavoritesRouterInput: AnyObject {
    func showUserDetail(username: String)
}
