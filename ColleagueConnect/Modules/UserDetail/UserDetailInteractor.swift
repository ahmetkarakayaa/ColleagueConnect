
import Foundation

final class UserDetailInteractor: UserDetailInteractorInput {

    private let networkClient: NetworkClientProtocol
    private let favoriteStorage: FavoriteStorageServiceProtocol
    private let authService: AuthServiceProtocol
    private let followStatusStore: FollowStatusStoreProtocol

    init(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        authService: AuthServiceProtocol,
        followStatusStore: FollowStatusStoreProtocol
    ) {
        self.networkClient = networkClient
        self.favoriteStorage = favoriteStorage
        self.authService = authService
        self.followStatusStore = followStatusStore
    }

    @MainActor
    func cachedFollowStatus(username: String) -> Bool? {
        followStatusStore.status(for: username)
    }

    @MainActor
    func shouldRefreshFollowStatus(username: String) -> Bool {
        followStatusStore.shouldRefreshStatus(for: username)
    }

    func fetchUser(
        username: String
    ) async throws -> UserDetailEntity {

        let token = try accessToken()

        let dto: UserDetailDTO = try await networkClient.request(
            endpoint: GitHubEndpoint.authenticatedUserDetail(
                username: username,
                token: token
            )
        )

        try Task.checkCancellation()

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

    func isFollowing(
        username: String
    ) async throws -> Bool {

        let expectedSession = await followStatusStore
            .currentSessionVersion()

        let expectedRevision = await followStatusStore
            .revision(for: username)

        let token = try accessToken()

        let status = try await networkClient.requestStatus(
            endpoint: GitHubEndpoint.checkFollowing(
                username: username,
                token: token
            )
        )

        let following: Bool

        switch status {
        case 204:
            following = true

        case 404:
            following = false

        default:
            throw NetworkError.invalidResponse
        }

        try Task.checkCancellation()

        guard await followStatusStore.currentSessionVersion()
                == expectedSession else {
            throw CancellationError()
        }

        let updated = await followStatusStore.setStatusIfUnchanged(
            following,
            for: username,
            expectedRevision: expectedRevision,
            expectedSessionVersion: expectedSession
        )

        if updated {
            return following
        }

        return await followStatusStore.status(
            for: username
        ) ?? following
    }

    func followUser(
        username: String
    ) async throws {

        let expectedSession = await followStatusStore
            .currentSessionVersion()

        let token = try accessToken()

        let status = try await networkClient.requestStatus(
            endpoint: GitHubEndpoint.followUser(
                username: username,
                token: token
            )
        )

        guard status == 204 else {
            throw NetworkError.invalidResponse
        }

        try Task.checkCancellation()

        let updated = await followStatusStore.setStatusIfCurrentSession(
            true,
            for: username,
            expectedSessionVersion: expectedSession
        )

        guard updated else {
            throw CancellationError()
        }
    }

    func unfollowUser(
        username: String
    ) async throws {

        let expectedSession = await followStatusStore
            .currentSessionVersion()

        let token = try accessToken()

        let status = try await networkClient.requestStatus(
            endpoint: GitHubEndpoint.unfollowUser(
                username: username,
                token: token
            )
        )

        guard status == 204 else {
            throw NetworkError.invalidResponse
        }

        try Task.checkCancellation()

        let updated = await followStatusStore.setStatusIfCurrentSession(
            false,
            for: username,
            expectedSessionVersion: expectedSession
        )

        guard updated else {
            throw CancellationError()
        }
    }

    private func accessToken() throws -> String {
        guard let token = try authService.accessToken(),
              !token.isEmpty else {
            throw AuthError.missingAccessToken
        }

        return token
    }
}
