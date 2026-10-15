import Foundation

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
}

protocol FavoritesInteractorInput {
    func getFavorites() -> [String]
    func removeFavorite(username: String)
    func fetchFavoriteUsers() async throws -> [FavoriteUserViewModel]
}

@MainActor
protocol FavoritesRouterInput: AnyObject {
    func showUserDetail(username: String)
}
