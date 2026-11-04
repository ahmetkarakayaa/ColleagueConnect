
import Foundation

final class UserDetailInteractor: UserDetailInteractorInput {
    
    private let networkClient: NetworkClientProtocol
    private let favoriteStorage: FavoriteStorageServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        authService: AuthServiceProtocol
    ) {
        self.networkClient = networkClient
        self.favoriteStorage = favoriteStorage
        self.authService = authService
    }
    
    func fetchUser(username: String) async throws -> UserDetailEntity {
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

        return dto.toEntity()
    }
    
    func isFavorite(username: String) -> Bool {
        favoriteStorage.isFavorite(username: username)
    }
    
    
    func toggleFavorite(username: String) -> Bool {
        if favoriteStorage.isFavorite(username: username) {
            favoriteStorage.removeFavorite(username: username)
            return false
        } else {
            favoriteStorage.addFavorite(username: username)
            return true
        }
    }
}
