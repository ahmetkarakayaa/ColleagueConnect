
import Foundation

final class FollowListInteractor: FollowListInteractorInput {

    private let networkClient: NetworkClientProtocol
    private let authService: AuthServiceProtocol
    private let followStatusStore: FollowStatusStoreProtocol

    init(
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol,
        followStatusStore: FollowStatusStoreProtocol
    ) {
        self.networkClient = networkClient
        self.authService = authService
        self.followStatusStore = followStatusStore
    }

    func fetchUsers(
        username: String,
        type: FollowListType,
        page: Int
    ) async throws -> [FollowListUserEntity] {

        guard let token = try authService.accessToken(),
              !token.isEmpty else {
            throw AuthError.missingAccessToken
        }

        let expectedGeneration = await followStatusStore
            .currentGeneration()

        let endpoint: GitHubEndpoint

        switch type {
        case .followers:
            endpoint = .followers(
                username: username,
                token: token,
                page: page
            )

        case .following:
            endpoint = .following(
                username: username,
                token: token,
                page: page
            )
        }

        let response: [FollowListDTO] = try await networkClient.request(
            endpoint: endpoint
        )

        try Task.checkCancellation()

        let users = response.map { $0.toEntity() }

        if type == .following {
            try Task.checkCancellation()

            await followStatusStore.cacheFollowingUsers(
                users.map { $0.username },
                expectedGeneration: expectedGeneration
            )
        }

        return users
    }
}
