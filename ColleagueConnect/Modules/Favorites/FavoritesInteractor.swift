
import Foundation

final class FavoritesInteractor: FavoritesInteractorInput {

    private let favoriteService: FavoriteStorageServiceProtocol
    private let networkClient: NetworkClientProtocol

    init(
        favoriteService: FavoriteStorageServiceProtocol =
            FavoriteStorageService(),
        networkClient: NetworkClientProtocol = NetworkClient()
    ) {
        self.favoriteService = favoriteService
        self.networkClient = networkClient
    }

    func getFavorites() -> [String] {
        favoriteService.getFavorites()
    }

    func removeFavorite(username: String) {
        favoriteService.removeFavorite(username: username)
    }

    func fetchFavoriteUsers() async throws -> [FavoriteUserViewModel] {
        let usernames = favoriteService.getFavorites()

        var users: [FavoriteUserViewModel] = []

        for username in usernames {
            let user: GitHubUser = try await networkClient.request(
                endpoint: GitHubEndpoint.userDetail(username: username)
            )

            let viewModel = FavoriteUserViewModel(
                username: user.login,
                avatarURL: user.avatarURL
            )

            users.append(viewModel)
        }

        return users
    }
}
