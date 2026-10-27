
import Foundation

final class WelcomeInteractor: WelcomeInteractorInput {

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func fetchWelcomeMessage() -> WelcomeMessage {
        WelcomeMessage(
            text: "Stay connected with your colleagues."
        )
    }

    func makeAuthorizationURL() throws -> URL {
        try authService.makeAuthorizationURL()
    }

    func handleCallback(_ url: URL) async throws {
        try await authService.handleCallback(url)
    }
}
