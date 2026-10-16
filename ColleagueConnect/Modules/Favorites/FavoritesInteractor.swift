
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


    func fetchFavoriteUsers() async throws -> [FavoriteUserViewModel] {
        let usernames = favoriteService.getFavorites()
        var users: [FavoriteUserViewModel] = []

        for username in usernames {
            try Task.checkCancellation()

            let dto: UserDetailDTO = try await networkClient.request(
                endpoint: GitHubEndpoint.userDetail(username: username)
            )

            try Task.checkCancellation()

            let detail = dto.toEntity()

            guard let avatarURL = detail.avatarURL
                ?? URL(string: "https://github.com/\(username).png") else {
                continue
            }

            users.append(
                FavoriteUserViewModel(
                    username: detail.login,
                    avatarURL: avatarURL,
                    name: detail.name,
                    bio: detail.bio
                )
            )
        }

        return users
    }
}
