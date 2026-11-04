
import Foundation

final class HomeInteractor: HomeInteractorInput {

    private let networkClient: NetworkClientProtocol
    private let authService: AuthServiceProtocol

    init(
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol
    ) {
        self.networkClient = networkClient
        self.authService = authService
    }

    func fetchCurrentUser() async throws -> UserDetailEntity {
        guard let token = try authService.accessToken(),
              !token.isEmpty else {
            throw AuthError.missingAccessToken
        }

        let dto: UserDetailDTO = try await networkClient.request(
            endpoint: GitHubEndpoint.authenticatedUser(token: token)
        )

        return dto.toEntity()
    }
}

enum HomeError: Error {
    case missingAccessToken
}
