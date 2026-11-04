
import Foundation

final class SearchInteractor: SearchInteractorInput {

    private let networkClient: NetworkClientProtocol
    private let authService: AuthServiceProtocol

    init(
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol
    ) {
        self.networkClient = networkClient
        self.authService = authService
    }

    func searchUsers(query: String) async throws -> GitHubSearchResponse {
        try await networkClient.request(
            endpoint: GitHubEndpoint.searchUsers(query: query)
        )
    }

    func fetchUserDetails(
        username: String
    ) async throws -> UserDetailEntity {
        let token = try authService.accessToken()

        let endpoint: GitHubEndpoint

        if let token, !token.isEmpty {
            endpoint = .authenticatedUserDetail(
                username: username,
                token: token
            )
        } else {
            endpoint = .userDetail(username: username)
        }

        let dto: UserDetailDTO = try await networkClient.request(
            endpoint: endpoint
        )

        return dto.toEntity()
    }
}
