
import Foundation

final class SearchInteractor: SearchInteractorInput {

    private let networkClient: NetworkClientProtocol
    private let favoriteService: FavoriteStorageServiceProtocol

    init(
        networkClient: NetworkClientProtocol,
        favoriteService: FavoriteStorageServiceProtocol
    ) {
        self.networkClient = networkClient
        self.favoriteService = favoriteService
    }


    func searchUsers(query: String) async throws -> [SearchUserEntity] {
        let response: GitHubSearchResponse = try await networkClient.request(
            endpoint: GitHubEndpoint.searchUsers(query: query)
        )

        return response.items.map { user in
            SearchUserEntity(
                id: user.id,
                username: user.login,
                avatarURL: user.avatarURL
            )
        }
    }


    func fetchUserDetails(
        username: String
    ) async throws -> UserDetailEntity {
        let dto: UserDetailDTO = try await networkClient.request(
            endpoint: GitHubEndpoint.userDetail(username: username)
        )
        return dto.toEntity()
    }


    func toggleFavorite(username: String) {
        if favoriteService.isFavorite(username: username) {
            favoriteService.removeFavorite(
                username: username
            )
        } else {
            favoriteService.addFavorite(
                username: username
            )
        }
    }

    func isFavorite(username: String) -> Bool {
        favoriteService.isFavorite(
            username: username
        )
    }
}
