import Foundation

@MainActor
protocol HomeViewInput: AnyObject {
    func displayLoading()
    func displayProfile(_ model: HomeViewModel)
    func displayError(_ message: String)
    func displayFavorites(_ model: HomeFavoritesViewModel)
    func displayRecentlyViewed(_ users: [HomeRecentFavoriteViewModel])
}

@MainActor
protocol HomeViewOutput: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func didTapRetry()
}

protocol HomeInteractorInput {
    func fetchCurrentUser() async throws -> UserDetailEntity
    func fetchFavorites() async throws -> HomeFavoritesSnapshot
    func fetchRecentlyViewed() async throws -> [FavoriteUserProfile]
}
