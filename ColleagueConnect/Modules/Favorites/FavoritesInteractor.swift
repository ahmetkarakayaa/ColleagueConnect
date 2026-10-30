
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

    func fetchFavoriteUser(username: String) async throws -> FavoriteUserProfile {
        try Task.checkCancellation()

        let dto: UserDetailDTO = try await networkClient.request(
            endpoint: GitHubEndpoint.userDetail(username: username)
        )

        try Task.checkCancellation()

        let detail = dto.toEntity()

        return FavoriteUserProfile(
            username: detail.login,
            avatarURL: detail.avatarURL,
            name: detail.name,
            bio: detail.bio
        )
    }
}
