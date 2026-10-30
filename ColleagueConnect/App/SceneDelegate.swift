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

        let appRouter = AppRouter(
            networkClient: NetworkClient(),
            favoriteStorage: FavoriteStorageService()
        )

        window.rootViewController = appRouter.makeInitialViewController()

        self.window = window
        window.makeKeyAndVisible()
    }
}
