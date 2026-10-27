
import XCTest
import Foundation
@testable import ColleagueConnect

final class  AuthServiceTests: XCTestCase {

    func testInvalidTokenResponseThrowsInvalidResponse() async throws {
        let callback = try makeCallbackURL()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, Data("invalid-json".utf8))
        }

        do {
            try await service.handleCallback(callback)
            XCTFail("Expected invalidResponse error")
        } catch AuthError.invalidResponse {
            XCTAssertNil(storage.token)
        }
    }

    func testInvalidCallbackIsRejected() async throws {
        _ = try service.makeAuthorizationURL()

        let callback = try XCTUnwrap(
            URL(string: "otherapp://auth?code=test&state=test")
        )

        do {
            try await service.handleCallback(callback)
            XCTFail("Expected invalidCallback")
        } catch AuthError.invalidCallback {
            XCTAssertNil(storage.token)
        }
    }

    func testMissingAuthorizationCodeIsRejected() async throws {
        let authorizationURL = try service.makeAuthorizationURL()
        let components = try XCTUnwrap(
            URLComponents(url: authorizationURL, resolvingAgainstBaseURL: false)
        )
        let state = try XCTUnwrap(
            components.queryItems?.first(where: { $0.name == "state" })?.value
        )

        var callback = URLComponents()
        callback.scheme = "colleagueconnect"
        callback.host = "auth"
        callback.queryItems = [URLQueryItem(name: "state", value: state)]

        do {
            try await service.handleCallback(
                try XCTUnwrap(callback.url)
            )
            XCTFail("Expected missingAuthorizationCode")
        } catch AuthError.missingAuthorizationCode {
            XCTAssertNil(storage.token)
        }
    }

    func testServerErrorDoesNotSaveToken() async throws {
        let callback = try makeCallbackURL()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, Data())
        }

        do {
            try await service.handleCallback(callback)
            XCTFail("Expected httpError")
        } catch AuthError.httpError(let statusCode) {
            XCTAssertEqual(statusCode, 500)
            XCTAssertNil(storage.token)
        }
    }



    private var storage: MockTokenStorage!
    private var session: URLSession!
    private var service: AuthService!

    override func setUp() {
        super.setUp()

        storage = MockTokenStorage()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)

        let oauthConfiguration = OAuthConfiguration(
            clientID: "test-client-id",
            clientSecret: "test-client-secret",
            redirectURI: "colleagueconnect://auth"
        )

        service = AuthService(
            configuration: oauthConfiguration,
            tokenStorage: storage,
            networkClient: NetworkClient(session: session)
        )
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        session.invalidateAndCancel()
        service = nil
        storage = nil
        session = nil
        super.tearDown()
    }

    func testAuthorizationURLContainsRequiredParameters() throws {
        let url = try service.makeAuthorizationURL()

        let components = try XCTUnwrap(
            URLComponents(url: url, resolvingAgainstBaseURL: false)
        )

        XCTAssertEqual(url.host, "github.com")
        XCTAssertEqual(url.path, "/login/oauth/authorize")

        let parameters = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? [])
                .compactMap { item -> (String, String)? in
                    guard let value = item.value else { return nil }
                    return (item.name, value)
                }
        )

        XCTAssertEqual(parameters["client_id"], "test-client-id")
        XCTAssertEqual(
            parameters["redirect_uri"],
            "colleagueconnect://auth"
        )
        XCTAssertFalse((parameters["state"] ?? "").isEmpty)
    }

    func testSuccessfulCallbackSavesAccessToken() async throws {
        let callback = try makeCallbackURL()

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(
                request.url?.absoluteString,
                "https://github.com/login/oauth/access_token"
            )

            let data = Data(
                #"{"access_token":"test-access-token"}"#.utf8
            )

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, data)
        }

        try await service.handleCallback(callback)

        XCTAssertEqual(storage.token, "test-access-token")
        XCTAssertTrue(try service.isLoggedIn())
    }

    func testInvalidStateDoesNotSaveToken() async throws {
        _ = try service.makeAuthorizationURL()

        let callback = try XCTUnwrap(
            URL(string: "colleagueconnect://auth?code=test&state=wrong")
        )

        do {
            try await service.handleCallback(callback)
            XCTFail("Expected invalidState error")
        } catch AuthError.invalidState {
            XCTAssertNil(storage.token)
        }
    }

    func testSignOutDeletesStoredToken() throws {
        storage.token = "saved-token"

        try service.signOut()

        XCTAssertNil(storage.token)
        XCTAssertFalse(try service.isLoggedIn())
    }

    func testMissingTokenMeansLoggedOut() throws {
        XCTAssertFalse(try service.isLoggedIn())
        XCTAssertNil(try service.accessToken())
    }

    private func makeCallbackURL() throws -> URL {
        let authorizationURL = try service.makeAuthorizationURL()

        let components = try XCTUnwrap(
            URLComponents(
                url: authorizationURL,
                resolvingAgainstBaseURL: false
            )
        )

        let state = try XCTUnwrap(
            components.queryItems?
                .first(where: { $0.name == "state" })?
                .value
        )

        var callback = URLComponents()
        callback.scheme = "colleagueconnect"
        callback.host = "auth"
        callback.queryItems = [
            URLQueryItem(name: "code", value: "test-code"),
            URLQueryItem(name: "state", value: state)
        ]

        return try XCTUnwrap(callback.url)
    }
}

private final class MockTokenStorage: TokenStorageProtocol {
    var token: String?

    func saveToken(_ token: String) throws {
        self.token = token
    }

    func getToken() throws -> String? {
        token
    }

    func deleteToken() throws {
        token = nil
    }
}

private final class MockURLProtocol: URLProtocol {

    static var requestHandler: ((
        URLRequest
    ) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.badServerResponse)
            )
            return
        }

        do {
            let (response, data) = try handler(request)

            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed
            )
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
