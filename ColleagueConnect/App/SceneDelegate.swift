
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
            authService: authService
        )

        window.rootViewController = appRouter.makeInitialViewController(
            onSignInSucceeded: { [weak window] in
                window?.rootViewController = appRouter.makeMainViewController()
            }
        )

        self.window = window
        window.makeKeyAndVisible()
    }
}
