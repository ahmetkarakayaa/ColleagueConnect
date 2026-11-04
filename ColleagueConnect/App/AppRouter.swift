
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
    func makeInitialViewController(
        onSignInSucceeded: @escaping () -> Void
    ) -> UIViewController {
        return WelcomeRouter.createModule(
            authService: authService,
            onSignInSucceeded: onSignInSucceeded
        )
    }

    func makeMainViewController() -> UIViewController {
        let searchViewController = SearchRouter.createModule(
            networkClient: networkClient,
            favoriteStorage: favoriteStorage
        )

        let favoritesViewController = FavoritesRouter.createModule(
            networkClient: networkClient,
            favoriteStorage: favoriteStorage,
            authService: authService
        )

        let searchNavigation = UINavigationController(
            rootViewController: searchViewController
        )

        let favoritesNavigation = UINavigationController(
            rootViewController: favoritesViewController
        )


        let homeViewController = HomeRouter.createModule(
            networkClient: networkClient,
            authService: authService,
            favoriteStorage: favoriteStorage
        )

        let homeNavigation = UINavigationController(
            rootViewController: homeViewController
        )


        let iconConfig = UIImage.SymbolConfiguration(
            pointSize: 19,
            weight: .regular
        )

        homeNavigation.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(
                systemName: "house",
                withConfiguration: iconConfig
            ),
            selectedImage: UIImage(
                systemName: "house.fill",
                withConfiguration: iconConfig
            )
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
            homeNavigation,
            searchNavigation,
            favoritesNavigation
        ]

        tabBarController.selectedIndex = 0


        homeViewController.onSeeAllFavorites = { [weak tabBarController] in
            tabBarController?.selectedIndex = 2
        }



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
