
import UIKit

@MainActor
enum WelcomeRouter {

    static func createModule(
        authService: AuthServiceProtocol
    ) -> UIViewController {
        let view = WelcomeViewController()

        let interactor = WelcomeInteractor(
            authService: authService
        )

        let presenter = WelcomePresenter(
            interactor: interactor
        )

        view.presenter = presenter
        presenter.view = view

        presenter.onAuthorizationRequested = {
            [weak view, weak presenter] url in

            guard let view else { return }

            presentOAuth(
                from: view,
                authorizationURL: url,
                callbackScheme: "colleagueconnect",
                onCallback: { [weak presenter] callbackURL in
                    presenter?.handleOAuthCallback(callbackURL)
                },
                onCancel: { [weak presenter] in
                    presenter?.cancelSignIn()
                },
                onError: { [weak presenter] in
                    presenter?.cancelSignIn()
                    presenter?.view?.displayError(
                        "Unable to load GitHub sign-in. Check your connection."
                    )
                }
            )
        }

        return view
    }

    static func presentOAuth(
        from view: UIViewController,
        authorizationURL: URL,
        callbackScheme: String,
        onCallback: @escaping (URL) -> Void,
        onCancel: @escaping () -> Void,
        onError: @escaping () -> Void
    ) {
        let dismissOAuth: (@escaping () -> Void) -> Void = {
            [weak view] completion in

            view?.dismiss(animated: true, completion: completion)
        }

        let oauthViewController = OAuthWebViewController(
            authorizationURL: authorizationURL,
            callbackScheme: callbackScheme,
            onCallback: { url in
                dismissOAuth {
                    onCallback(url)
                }
            },
            onCancel: {
                dismissOAuth {
                    onCancel()
                }
            },
            onError: {
                _ in

                dismissOAuth {
                    onError()
                }
            }
        )

        let navigationController = UINavigationController(
            rootViewController: oauthViewController
        )

        navigationController.modalPresentationStyle = .fullScreen

        view.present(
            navigationController,
            animated: true
        )
    }
}
