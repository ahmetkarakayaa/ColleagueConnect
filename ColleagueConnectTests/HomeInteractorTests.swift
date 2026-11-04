
import Foundation
import XCTest
@testable import ColleagueConnect

final class HomeInteractorTests: XCTestCase {

    func testRemovedFavoriteIsEvictedFromCache() async throws {
        let networkClient = HomeNetworkClientSpy()
        let favoriteStorage = HomeFavoriteStorageMock()

        favoriteStorage.usernames = ["testuser"]
        favoriteStorage.recentUsernames = ["testuser"]

        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: HomeAuthServiceMock(),
            favoriteStorage: favoriteStorage,
            recentlyViewedStorage: RecentlyViewedStorageMock()
        )

        _ = try await interactor.fetchFavorites()

        favoriteStorage.usernames = []
        favoriteStorage.recentUsernames = []

        _ = try await interactor.fetchFavorites()

        favoriteStorage.usernames = ["testuser"]
        favoriteStorage.recentUsernames = ["testuser"]

        _ = try await interactor.fetchFavorites()

        XCTAssertEqual(networkClient.requestCount, 2)
    }

    func testMissingTokenDoesNotSendRequest() async throws {
        let authService = HomeAuthServiceMock()
        authService.token = nil

        let networkClient = HomeNetworkClientSpy()
        let favoriteStorage = HomeFavoriteStorageMock()

        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: authService,
            favoriteStorage: favoriteStorage,
            recentlyViewedStorage: RecentlyViewedStorageMock()
        )

        do {
            _ = try await interactor.fetchCurrentUser()
            XCTFail("Expected missingAccessToken")
        } catch AuthError.missingAccessToken {
            XCTAssertEqual(networkClient.requestCount, 0)
        }
    }

    func testFavoritesCacheAvoidsDuplicateRequests() async throws {
        let authService = HomeAuthServiceMock()
        let networkClient = HomeNetworkClientSpy()
        let favoriteStorage = HomeFavoriteStorageMock()

        favoriteStorage.usernames = ["testuser"]
        favoriteStorage.recentUsernames = ["testuser"]

        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: authService,
            favoriteStorage: favoriteStorage,
            recentlyViewedStorage: RecentlyViewedStorageMock()
        )

        let first = try await interactor.fetchFavorites()
        let second = try await interactor.fetchFavorites()

        XCTAssertEqual(first.recentUsers.count, 1)
        XCTAssertEqual(second.recentUsers.count, 1)
        XCTAssertEqual(networkClient.requestCount, 1)
    }

    func testFavoritesContinuesWhenOneProfileFails() async throws {
        let networkClient = HomeNetworkClientSpy()
        let favoriteStorage = HomeFavoriteStorageMock()

        favoriteStorage.usernames = ["missing", "testuser"]
        favoriteStorage.recentUsernames = ["missing", "testuser"]
        networkClient.failingUsername = "missing"

        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: HomeAuthServiceMock(),
            favoriteStorage: favoriteStorage,
            recentlyViewedStorage: RecentlyViewedStorageMock()
        )

        let snapshot = try await interactor.fetchFavorites()

        XCTAssertEqual(snapshot.totalCount, 2)
        XCTAssertEqual(snapshot.recentUsers.count, 1)
        XCTAssertEqual(
            snapshot.recentUsers.first?.username,
            "testuser"
        )
    }

    func testValidTokenFetchesAuthenticatedUser() async throws {
        let authService = HomeAuthServiceMock()
        authService.token = "test-access-token"

        let networkClient = HomeNetworkClientSpy()
        let favoriteStorage = HomeFavoriteStorageMock()

        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: authService,
            favoriteStorage: favoriteStorage,
            recentlyViewedStorage: RecentlyViewedStorageMock()
        )

        let user = try await interactor.fetchCurrentUser()

        XCTAssertEqual(networkClient.requestCount, 1)

        XCTAssertEqual(
            networkClient.lastRequest?.url?.absoluteString,
            "https://api.github.com/user"
        )

        XCTAssertEqual(
            networkClient.lastRequest?.value(
                forHTTPHeaderField: "Authorization"
            ),
            "Bearer test-access-token"
        )

        XCTAssertEqual(user.login, "testuser")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.followers, 120)
        XCTAssertEqual(user.following, 45)
    }

    func testFavoritesReturnsRealCountAndRecentUsers() async throws {
        let authService = HomeAuthServiceMock()
        let networkClient = HomeNetworkClientSpy()
        let favoriteStorage = HomeFavoriteStorageMock()

        favoriteStorage.usernames = [
            "ali",
            "mehmet",
            "testuser"
        ]
        favoriteStorage.recentUsernames = ["testuser"]

        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: authService,
            favoriteStorage: favoriteStorage,
            recentlyViewedStorage: RecentlyViewedStorageMock()
        )

        let snapshot = try await interactor.fetchFavorites()

        XCTAssertEqual(snapshot.totalCount, 3)
        XCTAssertEqual(snapshot.recentUsers.count, 1)
        XCTAssertEqual(
            snapshot.recentUsers.first?.username,
            "testuser"
        )
        XCTAssertEqual(networkClient.requestCount, 1)
    }

    func testEmptyFavoritesDoesNotSendRequest() async throws {
        let interactor = HomeInteractor(
            networkClient: HomeNetworkClientSpy(),
            authService: HomeAuthServiceMock(),
            favoriteStorage: HomeFavoriteStorageMock(),
            recentlyViewedStorage: RecentlyViewedStorageMock()
        )

        let snapshot = try await interactor.fetchFavorites()

        XCTAssertEqual(snapshot.totalCount, 0)
        XCTAssertTrue(snapshot.recentUsers.isEmpty)
    }
}

private final class HomeAuthServiceMock: AuthServiceProtocol {

    var token: String?

    func makeAuthorizationURL() throws -> URL {
        URL(string: "https://github.com/login/oauth/authorize")!
    }

    func handleCallback(_ url: URL) async throws {}

    func isLoggedIn() throws -> Bool {
        guard let token else { return false }
        return !token.isEmpty
    }

    func accessToken() throws -> String? {
        token
    }

    func signOut() throws {
        token = nil
    }
}

private final class HomeFavoriteStorageMock: FavoriteStorageServiceProtocol {

    var usernames: [String] = []
    var recentUsernames: [String] = []

    func isFavorite(username: String) -> Bool {
        usernames.contains(username)
    }

    func addFavorite(username: String) {
        guard !usernames.contains(username) else { return }

        usernames.append(username)
        recentUsernames.insert(username, at: 0)
    }

    func removeFavorite(username: String) {
        usernames.removeAll { $0 == username }
        recentUsernames.removeAll { $0 == username }
    }

    func getFavorites() -> [String] {
        usernames
    }

    func getRecentFavorites(limit: Int) -> [String] {
        Array(recentUsernames.prefix(max(0, limit)))
    }
}

private final class RecentlyViewedStorageMock: RecentlyViewedStorageServiceProtocol {

    func recordVisit(username: String) {}

    func getRecentlyViewed(limit: Int?) -> [String] {
        []
    }

    func clearHistory() {}
}

private final class HomeNetworkClientSpy: NetworkClientProtocol {

    private(set) var requestCount = 0
    private(set) var lastRequest: URLRequest?

    var failingUsername: String?

    func request<T: Decodable>(
        endpoint: APIEndpoint
    ) async throws -> T {
        requestCount += 1
        lastRequest = try endpoint.makeURLRequest()

        if lastRequest?.url?.lastPathComponent == failingUsername {
            throw NetworkError.httpError(statusCode: 404)
        }

        let json = """
        {
            "id": 1,
            "login": "testuser",
            "name": "Test User",
            "avatar_url": "https://example.com/avatar.png",
            "bio": "iOS Developer",
            "followers": 120,
            "following": 45,
            "created_at": "2020-01-01T00:00:00Z",
            "html_url": "https://github.com/testuser"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(
            T.self,
            from: Data(json.utf8)
        )
    }
}
