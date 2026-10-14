
import Foundation

final class SearchInteractor: SearchInteractorInput {

    private let networkClient: NetworkClientProtocol
    private let favoriteService: FavoriteStorageServiceProtocol

    init(
        networkClient: NetworkClientProtocol = NetworkClient(),
        favoriteService: FavoriteStorageServiceProtocol =
            FavoriteStorageService()
    ) {
        self.networkClient = networkClient
        self.favoriteService = favoriteService
    }

    func searchUsers(query: String) async throws -> [GitHubUser] {
        let response: GitHubSearchResponse =
            try await networkClient.request(
                endpoint: GitHubEndpoint.searchUsers(query: query)
            )

        return response.items
    }

    func toggleFavorite(username: String) {
        if favoriteService.isFavorite(username: username) {
            favoriteService.removeFavorite(username: username)
        } else {
            favoriteService.addFavorite(username: username)
        }
    }

    func isFavorite(username: String) -> Bool {
        return favoriteService.isFavorite(username: username)
    }
}
