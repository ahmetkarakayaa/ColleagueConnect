
import Foundation

final class UserDetailInteractor: UserDetailInteractorInput {
    
    private let networkClient: NetworkClientProtocol
    private let favoriteStorage: FavoriteStorageServiceProtocol
    
    init(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol
    ) {
        self.networkClient = networkClient
        self.favoriteStorage = favoriteStorage
    }
    
    func fetchUser(username: String) async throws -> UserDetailEntity {
        let dto: UserDetailDTO = try await networkClient.request(
            endpoint: GitHubEndpoint.userDetail(username: username)
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
