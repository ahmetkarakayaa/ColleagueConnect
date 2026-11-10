import Foundation

final class HomeInteractor: HomeInteractorInput {


    private enum Constants {
        static let previewLimit = 3
    }


    private let networkClient: NetworkClientProtocol
    private let authService: AuthServiceProtocol
    private let favoriteStorage: FavoriteStorageServiceProtocol
    private let recentlyViewedStorage: RecentlyViewedStorageServiceProtocol
    private let profileCache = HomeFavoriteProfileCache()


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

    // MARK: - HomeInteractorInput

    func fetchCurrentUser() async throws -> UserDetailEntity {
        let token = try validAccessToken()

        let dto: UserDetailDTO = try await networkClient.request(
            endpoint: GitHubEndpoint.authenticatedUser(token: token)
        )

        return dto.toEntity()
    }

    func fetchFavorites() async throws -> HomeFavoritesSnapshot {
        let favorites = favoriteStorage.getFavorites()
        let usernames = favoriteStorage.getRecentFavorites(limit: Constants.previewLimit)

        await profileCache.retain(favorites)

        var profilesByUsername: [String: FavoriteUserProfile] = [:]
        var missingUsernames: [String] = []

        for username in usernames {
            if let cached = await profileCache.profile(for: username) {
                profilesByUsername[username] = cached
            } else {
                missingUsernames.append(username)
            }
        }

        if !missingUsernames.isEmpty {
            let token = try validAccessToken()
            let fetched = try await fetchProfiles(usernames: missingUsernames, token: token)

            for (username, profile) in fetched {
                await profileCache.save(profile, for: username)
                profilesByUsername[username] = profile
            }
        }

        // Storage'daki sıralamayı koru; çekilemeyen kullanıcılar atlanır.
        let recentUsers = usernames.compactMap { profilesByUsername[$0] }

        return HomeFavoritesSnapshot(
            totalCount: favorites.count,
            recentUsers: recentUsers
        )
    }

    func fetchRecentlyViewed() async throws -> [FavoriteUserProfile] {
        let usernames = recentlyViewedStorage.getRecentlyViewed(limit: Constants.previewLimit)

        guard !usernames.isEmpty else {
            return []
        }

        let token = try validAccessToken()
        let profilesByUsername = try await fetchProfiles(usernames: usernames, token: token)

        return usernames.compactMap { profilesByUsername[$0] }
    }


    private func validAccessToken() throws -> String {
        guard let token = try authService.accessToken(), !token.isEmpty else {
            throw AuthError.missingAccessToken
        }
        return token
    }

    private func fetchProfile(
        username: String,
        token: String
    ) async throws -> FavoriteUserProfile {
        let dto: UserDetailDTO = try await networkClient.request(
            endpoint: GitHubEndpoint.authenticatedUserDetail(
                username: username,
                token: token
            )
        )

        try Task.checkCancellation()

        let user = dto.toEntity()

        return FavoriteUserProfile(
            username: user.login,
            avatarURL: user.avatarURL,
            name: user.name,
            bio: user.bio
        )
    }


    private func fetchProfiles(
        usernames: [String],
        token: String
    ) async throws -> [String: FavoriteUserProfile] {
        try await withThrowingTaskGroup(of: (String, FavoriteUserProfile?).self) { group in
            for username in usernames {
                group.addTask { [self] in
                    do {
                        let profile = try await fetchProfile(username: username, token: token)
                        return (username, profile)
                    } catch {
                        
                        try Task.checkCancellation()
                        return (username, nil)
                    }
                }
            }

            var result: [String: FavoriteUserProfile] = [:]

            for try await (username, profile) in group {
                if let profile {
                    result[username] = profile
                }
            }

            return result
        }
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
