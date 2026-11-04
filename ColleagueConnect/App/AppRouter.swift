
import UIKit

@MainActor
final class AppRouter {

    private let networkClient: NetworkClientProtocol
    private let favoriteStorage: FavoriteStorageServiceProtocol
    private let authService: AuthServiceProtocol

    init(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        authService: AuthServiceProtocol
    ) {
        self.networkClient = networkClient
        self.favoriteStorage = favoriteStorage
        self.authService = authService
    }
    func makeInitialViewController() -> UIViewController {
        if ProcessInfo.processInfo.arguments.contains("-showLoginUI") {
            return WelcomeRouter.createModule(
                authService: authService
            )
        }

        let searchViewController = SearchRouter.createModule(
            networkClient: networkClient,
            favoriteStorage: favoriteStorage
        )

        let favoritesViewController = FavoritesRouter.createModule(
            networkClient: networkClient,
            favoriteStorage: favoriteStorage
        )

        let searchNavigation = UINavigationController(
            rootViewController: searchViewController
        )

        let favoritesNavigation = UINavigationController(
            rootViewController: favoritesViewController
        )

        let iconConfig = UIImage.SymbolConfiguration(
            pointSize: 19,
            weight: .regular
        )

        searchNavigation.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(
                systemName: "magnifyingglass",
                withConfiguration: iconConfig
            ),
            selectedImage: UIImage(
                systemName: "magnifyingglass",
                withConfiguration: iconConfig
            )
        )

        favoritesNavigation.tabBarItem = UITabBarItem(
            title: "Favorites",
            image: UIImage(
                systemName: "heart",
                withConfiguration: iconConfig
            ),
            selectedImage: UIImage(
                systemName: "heart",
                withConfiguration: iconConfig
            )
        )

        let tabBarController = UITabBarController()

        tabBarController.viewControllers = [
            searchNavigation,
            favoritesNavigation
        ]

        tabBarController.tabBar.tintColor = AppTheme.Colors.accent
        tabBarController.tabBar.unselectedItemTintColor = .secondaryLabel

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(
                ofSize: 10,
                weight: .regular
            )
        ]

        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(
                ofSize: 10,
                weight: .medium
            )
        ]

        for itemAppearance in [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ] {
            itemAppearance.normal.titleTextAttributes = normalAttributes
            itemAppearance.selected.titleTextAttributes = selectedAttributes
        }

        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance

        return tabBarController
    }
}
