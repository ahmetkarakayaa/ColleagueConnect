
import Foundation

@MainActor
final class WelcomePresenter: WelcomeViewOutput {

    weak var view: WelcomeViewInput?

    private let interactor: WelcomeInteractorInput
    private var isSigningIn = false

    var onAuthorizationRequested: ((URL) -> Void)?
    var onSignInSucceeded: (() -> Void)?

    init(interactor: WelcomeInteractorInput) {
        self.interactor = interactor
    }

    func viewDidLoad() {
        let message = interactor.fetchWelcomeMessage()
        view?.displayWelcomeMessage(message.text)
    }

    func didTapSignIn() {
        guard !isSigningIn else { return }

        guard let onAuthorizationRequested else {
            view?.displayError(
                "GitHub sign-in is unavailable."
            )
            return
        }

        do {
            let url = try interactor.makeAuthorizationURL()

            isSigningIn = true
            onAuthorizationRequested(url)
        } catch {
            view?.displayError(
                "Unable to start GitHub sign-in. Please try again."
            )
        }
    }

    func handleOAuthCallback(_ url: URL) {
        guard isSigningIn else { return }

        view?.setLoading(true)

        Task { [weak self] in
            guard let self else { return }

            defer {
                self.view?.setLoading(false)
                self.isSigningIn = false
            }

            do {
                try await self.interactor.handleCallback(url)
                self.onSignInSucceeded?()            } catch is CancellationError {
                return
            } catch {
                self.view?.displayError(
                    "GitHub sign-in failed. Please try again."
                )
            }
        }
    }

    func cancelSignIn() {
        isSigningIn = false
        view?.setLoading(false)
    }
}
