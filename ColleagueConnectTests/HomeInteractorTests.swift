
import Foundation
import XCTest
@testable import ColleagueConnect

final class HomeInteractorTests: XCTestCase {

    func testMissingTokenDoesNotSendRequest() async throws {
        let authService = HomeAuthServiceMock()
        let networkClient = HomeNetworkClientSpy()

        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: authService
        )

        do {
            _ = try await interactor.fetchCurrentUser()
            XCTFail("Expected missingAccessToken")
        } catch AuthError.missingAccessToken {
            XCTAssertEqual(networkClient.requestCount, 0)
        }
    }

    func testValidTokenFetchesAuthenticatedUser() async throws {
        let authService = HomeAuthServiceMock()
        authService.token = "test-access-token"

        let networkClient = HomeNetworkClientSpy()

        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: authService
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
}

private final class HomeAuthServiceMock: AuthServiceProtocol {

    var token: String?

    func makeAuthorizationURL() throws -> URL {
        URL(string: "https://github.com/login/oauth/authorize")!
    }

    func handleCallback(_ url: URL) async throws {}

    func isLoggedIn() throws -> Bool {
        token != nil && !token!.isEmpty
    }

    func accessToken() throws -> String? {
        token
    }

    func signOut() throws {
        token = nil
    }
}

private final class HomeNetworkClientSpy: NetworkClientProtocol {

    private(set) var requestCount = 0
    private(set) var lastRequest: URLRequest?

    func request<T: Decodable>(
        endpoint: APIEndpoint
    ) async throws -> T {
        requestCount += 1
        lastRequest = try endpoint.makeURLRequest()

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
