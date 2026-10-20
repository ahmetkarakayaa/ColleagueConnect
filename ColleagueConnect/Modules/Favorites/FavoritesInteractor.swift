
import Foundation

final class FavoritesInteractor: FavoritesInteractorInput {

    private let favoriteService: FavoriteStorageServiceProtocol
    private let networkClient: NetworkClientProtocol

    init(
        favoriteService: FavoriteStorageServiceProtocol,
        networkClient: NetworkClientProtocol
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


    func fetchFavoriteUsers() async throws -> [UserDetailDTO] {
        let usernames = favoriteService.getFavorites()
        var users: [UserDetailDTO] = []

        for username in usernames {
            try Task.checkCancellation()

            let dto: UserDetailDTO = try await networkClient.request(
                endpoint: GitHubEndpoint.userDetail(username: username)
            )

            try Task.checkCancellation()
            users.append(dto)
        }

        return users
    }
}
