
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)

        let networkClient = NetworkClient()
        let tokenStorage = KeychainTokenStorage()

        let configuration = OAuthConfiguration(
            clientID: Bundle.main.object(
                forInfoDictionaryKey: "GITHUB_CLIENT_ID"
            ) as? String ?? "",
            clientSecret: Bundle.main.object(
                forInfoDictionaryKey: "GITHUB_CLIENT_SECRET"
            ) as? String ?? "",
            redirectURI: "colleagueconnect://auth"
        )

        let authService = AuthService(
            configuration: configuration,
            tokenStorage: tokenStorage,
            networkClient: networkClient
        )

        let appRouter = AppRouter(
            networkClient: networkClient,
            favoriteStorage: FavoriteStorageService(),
            authService: authService,
            recentlyViewedStorage: RecentlyViewedStorageService()
        )

        do {
            if try authService.isLoggedIn() {
                showMain(
                    in: window,
                    router: appRouter,
                    authService: authService
                )
            } else {
                showWelcome(
                    in: window,
                    router: appRouter,
                    authService: authService
                )
            }
        } catch {
            showWelcome(
                in: window,
                router: appRouter,
                authService: authService
            )
        }


        self.window = window
        window.makeKeyAndVisible()
        _ = AppInternetMonitor.shared
    }

    private func showMain(
        in window: UIWindow,
        router: AppRouter,
        authService: AuthServiceProtocol
    ) {
        window.rootViewController = router.makeMainViewController(
            onLogoutRequested: { [weak self, weak window] in
                guard let window else { return }

                let confirmation = UIAlertController(
                    title: "Log Out",
                    message: "Are you sure you want to log out?",
                    preferredStyle: .alert
                )

                confirmation.addAction(
                    UIAlertAction(
                        title: "Cancel",
                        style: .cancel
                    )
                )

                confirmation.addAction(
                    UIAlertAction(
                        title: "Log Out",
                        style: .destructive
                    ) { [weak self, weak window] _ in
                        guard let self, let window else { return }

                        do {
                            try authService.signOut()

                            self.showWelcome(
                                in: window,
                                router: router,
                                authService: authService
                            )
                        } catch {
                            let alert = UIAlertController(
                                title: "Logout Failed",
                                message: "Please try again.",
                                preferredStyle: .alert
                            )

                            alert.addAction(
                                UIAlertAction(title: "OK", style: .default)
                            )

                            window.rootViewController?.present(
                                alert,
                                animated: true
                            )
                        }
                    }
                )

                window.rootViewController?.present(
                    confirmation,
                    animated: true
                )
            }
        )
    }

    private func showWelcome(
        in window: UIWindow,
        router: AppRouter,
        authService: AuthServiceProtocol
    ) {
        window.rootViewController = router.makeInitialViewController(
            onSignInSucceeded: { [weak self, weak window] in
                guard let self, let window else { return }

                self.showMain(
                    in: window,
                    router: router,
                    authService: authService
                )
            }
        )
    }

}
