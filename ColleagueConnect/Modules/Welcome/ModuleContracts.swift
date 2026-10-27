
import Foundation

protocol WelcomeViewInput: AnyObject {
    func displayWelcomeMessage(_ message: String)
    func setLoading(_ isLoading: Bool)
    func displayError(_ message: String)
}

protocol WelcomeViewOutput: AnyObject {
    func viewDidLoad()
    func didTapSignIn()
}

protocol WelcomeInteractorInput {
    func fetchWelcomeMessage() -> WelcomeMessage
    func makeAuthorizationURL() throws -> URL
    func handleCallback(_ url: URL) async throws
}
