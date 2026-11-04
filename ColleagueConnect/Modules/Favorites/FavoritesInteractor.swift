
import Foundation

final class FavoritesInteractor: FavoritesInteractorInput {

    private let favoriteService: FavoriteStorageServiceProtocol
    private let networkClient: NetworkClientProtocol
    private let authService: AuthServiceProtocol

    init(
        favoriteService: FavoriteStorageServiceProtocol,
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol
    ) {
        self.favoriteService = favoriteService
        self.networkClient = networkClient
        self.authService = authService
    }

    func getFavorites() -> [String] {
        favoriteService.getFavorites()
    }

    func removeFavorite(username: String) {
        favoriteService.removeFavorite(username: username)
    }

    func fetchFavoriteUser(username: String) async throws -> FavoriteUserProfile {
        try Task.checkCancellation()

        guard let token = try authService.accessToken(),
              !token.isEmpty else {
            throw AuthError.missingAccessToken
        }

        let dto: UserDetailDTO = try await networkClient.request(
            endpoint: GitHubEndpoint.authenticatedUserDetail(
                username: username,
                token: token
            )
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
