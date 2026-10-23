
import XCTest
@testable import ColleagueConnect

final class OAuthComponentTests: XCTestCase {

    private let configuration = OAuthConfiguration(
        clientID: "test-client-id",
        clientSecret: "test-client-secret",
        redirectURI: "colleagueconnect://auth"
    )

    func testAuthorizationURLContainsExpectedParameters() throws {
        let endpoint = GitHubAuthEndpoint(configuration: configuration)

        let url = try endpoint.authorizationURL(state: "test-state")
        let components = try XCTUnwrap(
            URLComponents(url: url, resolvingAgainstBaseURL: false)
        )

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "github.com")
        XCTAssertEqual(components.path, "/login/oauth/authorize")

        XCTAssertEqual(
            components.queryItems?.first { $0.name == "client_id" }?.value,
            "test-client-id"
        )
        XCTAssertEqual(
            components.queryItems?.first { $0.name == "state" }?.value,
            "test-state"
        )
    }

    func testTokenRequestUsesPOSTAndFormBody() throws {
        let endpoint = GitHubAuthEndpoint(configuration: configuration)

        let request = try endpoint.tokenRequest(code: "test-code")

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://github.com/login/oauth/access_token"
        )
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Content-Type"),
            "application/x-www-form-urlencoded"
        )
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Accept"),
            "application/json"
        )

        let bodyData = try XCTUnwrap(request.httpBody)
        let bodyString = try XCTUnwrap(
            String(data: bodyData, encoding: .utf8)
        )
        let body = try XCTUnwrap(URLComponents(
            string: "https://example.com/?" + bodyString
        ))

        XCTAssertEqual(
            body.queryItems?.first { $0.name == "client_id" }?.value,
            "test-client-id"
        )
        XCTAssertEqual(
            body.queryItems?.first { $0.name == "client_secret" }?.value,
            "test-client-secret"
        )
        XCTAssertEqual(
            body.queryItems?.first { $0.name == "code" }?.value,
            "test-code"
        )
    }

    func testCallbackReturnsCodeWhenStateMatches() throws {
        let parser = OAuthCallbackParser(
            redirectURI: configuration.redirectURI
        )

        let url = try XCTUnwrap(
            URL(string: "colleagueconnect://auth?code=abc123&state=valid")
        )

        let code = try parser.authorizationCode(
            from: url,
            expectedState: "valid"
        )

        XCTAssertEqual(code, "abc123")
    }

    func testCallbackRejectsInvalidState() throws {
        let parser = OAuthCallbackParser(
            redirectURI: configuration.redirectURI
        )

        let url = try XCTUnwrap(
            URL(string: "colleagueconnect://auth?code=abc123&state=wrong")
        )

        XCTAssertThrowsError(
            try parser.authorizationCode(
                from: url,
                expectedState: "correct"
            )
        ) { error in
            guard case AuthError.invalidState = error else {
                return XCTFail("Expected invalidState, got \(error)")
            }
        }
    }

    func testCallbackRejectsWrongRedirectURL() throws {
        let parser = OAuthCallbackParser(
            redirectURI: configuration.redirectURI
        )

        let url = try XCTUnwrap(
            URL(string: "otherapp://auth?code=abc123&state=valid")
        )

        XCTAssertThrowsError(
            try parser.authorizationCode(
                from: url,
                expectedState: "valid"
            )
        ) { error in
            guard case AuthError.invalidCallback = error else {
                return XCTFail("Expected invalidCallback, got \(error)")
            }
        }
    }

    func testCallbackRejectsMissingCode() throws {
        let parser = OAuthCallbackParser(
            redirectURI: configuration.redirectURI
        )

        let url = try XCTUnwrap(
            URL(string: "colleagueconnect://auth?state=valid")
        )

        XCTAssertThrowsError(
            try parser.authorizationCode(
                from: url,
                expectedState: "valid"
            )
        ) { error in
            guard case AuthError.missingAuthorizationCode = error else {
                return XCTFail("Expected missingAuthorizationCode, got \(error)")
            }
        }
    }

    func testCallbackReportsGitHubAuthorizationError() throws {
        let parser = OAuthCallbackParser(
            redirectURI: configuration.redirectURI
        )

        let url = try XCTUnwrap(
            URL(string: "colleagueconnect://auth?error=access_denied&state=valid")
        )

        XCTAssertThrowsError(
            try parser.authorizationCode(
                from: url,
                expectedState: "valid"
            )
        ) { error in
            guard case AuthError.authorizationFailed(let message) = error else {
                return XCTFail("Expected authorizationFailed, got \(error)")
            }

            XCTAssertEqual(message, "access_denied")
        }
    }
}
