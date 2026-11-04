
import Foundation

final class HomeInteractor: HomeInteractorInput {

    private let networkClient: NetworkClientProtocol
    private let authService: AuthServiceProtocol
    private let favoriteStorage: FavoriteStorageServiceProtocol
    private let profileCache = HomeFavoriteProfileCache()
    private let recentlyViewedStorage: RecentlyViewedStorageServiceProtocol

    init(
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        recentlyViewedStorage: RecentlyViewedStorageServiceProtocol
    ) {
        self.networkClient = networkClient
        self.authService = authService
        self.favoriteStorage = favoriteStorage
        self.recentlyViewedStorage = recentlyViewedStorage
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


    func fetchFavorites() async throws -> HomeFavoritesSnapshot {
        let favorites = favoriteStorage.getFavorites()
        let usernames = favoriteStorage.getRecentFavorites(limit: 3)

        await profileCache.retain(favorites)

        var recentUsers: [FavoriteUserProfile] = []

        for username in usernames {
            try Task.checkCancellation()

            if let cached = await profileCache.profile(for: username) {
                recentUsers.append(cached)
                continue
            }

            do {
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

                let user = dto.toEntity()

                let profile = FavoriteUserProfile(
                    username: user.login,
                    avatarURL: user.avatarURL,
                    name: user.name,
                    bio: user.bio
                )

                recentUsers.append(profile)
                await profileCache.save(profile, for: username)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                continue
            }
        }

        return HomeFavoritesSnapshot(
            totalCount: favorites.count,
            recentUsers: recentUsers
        )
    }
    func fetchRecentlyViewed() async throws -> [FavoriteUserProfile] {
        let usernames = recentlyViewedStorage.getRecentlyViewed(limit: 3)

        guard !usernames.isEmpty else {
            return []
        }

        guard let token = try authService.accessToken(),
              !token.isEmpty else {
            throw AuthError.missingAccessToken
        }

        var profiles: [FavoriteUserProfile] = []

        for username in usernames {
            try Task.checkCancellation()

            do {
                let dto: UserDetailDTO = try await networkClient.request(
                    endpoint: GitHubEndpoint.authenticatedUserDetail(
                        username: username,
                        token: token
                    )
                )

                try Task.checkCancellation()

                let user = dto.toEntity()

                profiles.append(
                    FavoriteUserProfile(
                        username: user.login,
                        avatarURL: user.avatarURL,
                        name: user.name,
                        bio: user.bio
                    )
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                continue
            }
        }

        return profiles
    }

    private actor HomeFavoriteProfileCache {

        private var profiles: [String: FavoriteUserProfile] = [:]

        func profile(for username: String) -> FavoriteUserProfile? {
            profiles[username]
        }

        func save(_ profile: FavoriteUserProfile, for username: String) {
            profiles[username] = profile
        }

        func retain(_ usernames: [String]) {
            let allowed = Set(usernames)
            profiles = profiles.filter { allowed.contains($0.key) }
        }
    }


}
