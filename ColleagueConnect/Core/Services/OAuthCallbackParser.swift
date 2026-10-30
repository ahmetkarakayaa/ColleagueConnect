
import Foundation

struct OAuthCallbackParser {

    let redirectURI: String

    func authorizationCode(
        from callbackURL: URL,
        expectedState: String?
    ) throws -> String {

        guard let expectedURL = URL(string: redirectURI),
              callbackURL.scheme == expectedURL.scheme,
              callbackURL.host == expectedURL.host,
              callbackURL.path == expectedURL.path,
              let components = URLComponents(
                url: callbackURL,
                resolvingAgainstBaseURL: false
              ) else {
            throw AuthError.invalidCallback
        }

        let items = components.queryItems ?? []

        func parameter(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        guard let expectedState,
              let receivedState = parameter("state"),
              receivedState == expectedState else {
            throw AuthError.invalidState
        }

        if let error = parameter("error") {
            throw AuthError.authorizationFailed(error)
        }

        guard let code = parameter("code"),
              !code.isEmpty else {
            throw AuthError.missingAuthorizationCode
        }

        return code
    }
}
