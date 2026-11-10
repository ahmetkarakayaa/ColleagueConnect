
import UIKit

@MainActor
final class AppRouter {

    private let networkClient: NetworkClientProtocol
    private let favoriteStorage: FavoriteStorageServiceProtocol
    private let authService: AuthServiceProtocol
    private let recentlyViewedStorage: RecentlyViewedStorageServiceProtocol

    init(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        authService: AuthServiceProtocol,
        recentlyViewedStorage: RecentlyViewedStorageServiceProtocol
    ) {
        self.networkClient = networkClient
        self.favoriteStorage = favoriteStorage
        self.authService = authService
        self.recentlyViewedStorage = recentlyViewedStorage
    }
    func makeInitialViewController(
        onSignInSucceeded: @escaping () -> Void
    ) -> UIViewController {
        return WelcomeRouter.createModule(
            authService: authService,
            onSignInSucceeded: onSignInSucceeded
        )
    }

    func makeMainViewController(
        onLogoutRequested: @escaping () -> Void
    ) -> UIViewController {
        let searchViewController = SearchRouter.createModule(
            networkClient: networkClient,
            favoriteStorage: favoriteStorage,
            authService: authService,
            recentlyViewedStorage: recentlyViewedStorage
        )
        let favoritesViewController = FavoritesRouter.createModule(
            networkClient: networkClient,
            favoriteStorage: favoriteStorage,
            authService: authService,
            recentlyViewedStorage: recentlyViewedStorage
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
            favoriteStorage: favoriteStorage,
            recentlyViewedStorage: recentlyViewedStorage
        )
        let homeNavigation = UINavigationController(
            rootViewController: homeViewController
        )
        homeViewController.navigationItem.backButtonDisplayMode = .minimal
        homeNavigation.navigationBar.tintColor = AppTheme.Colors.accent
        homeViewController.onProfileTapped = {
            [weak homeNavigation, weak homeViewController] profile in

            let profileViewController = MyProfileViewController(
                profile: profile
            )

            profileViewController.onOpenGitHubProfile = {
                [weak homeViewController] in
                homeViewController?.onOpenGitHubProfile?(profile.username)
            }

            profileViewController.onLogoutRequested = {
                [weak homeViewController] in
                homeViewController?.onLogoutRequested?()
            }

            homeNavigation?.pushViewController(
                profileViewController,
                animated: true
            )
        }

        homeViewController.onRecentFavoriteTapped = { [weak homeNavigation] username in
            let detailViewController = UserDetailRouter.createModule(
                username: username,
                networkClient: self.networkClient,
                favoriteStorage: self.favoriteStorage,
                authService: self.authService,
                recentlyViewedStorage: self.recentlyViewedStorage
            )
            homeNavigation?.pushViewController(
                detailViewController,
                animated: true
            )
        }
        homeViewController.onViewedProfileTapped = { [weak homeNavigation] username in
            let detail = UserDetailRouter.createModule(
                username: username,
                networkClient: self.networkClient,
                favoriteStorage: self.favoriteStorage,
                authService: self.authService,
                recentlyViewedStorage: self.recentlyViewedStorage
            )
            homeNavigation?.pushViewController(detail, animated: true)
        }

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
        homeViewController.onSeeAllViewed = { [weak homeNavigation] in
            let historyViewController = RecentlyViewedViewController(
                storage: self.recentlyViewedStorage,
                networkClient: self.networkClient,
                authService: self.authService,
                onSelectProfile: { [weak homeNavigation] username in
                    let detail = UserDetailRouter.createModule(
                        username: username,
                        networkClient: self.networkClient,
                        favoriteStorage: self.favoriteStorage,
                        authService: self.authService,
                        recentlyViewedStorage: self.recentlyViewedStorage
                    )
                    homeViewController.navigationItem.backButtonDisplayMode = .minimal
                    homeNavigation?.navigationBar.tintColor = AppTheme.Colors.accent

                    homeNavigation?.pushViewController(
                        detail,
                        animated: true
                    )
                }
            )

            homeNavigation?.pushViewController(
                historyViewController,
                animated: true
            )
        }
        homeViewController.onLogoutRequested = onLogoutRequested
        homeViewController.onOpenGitHubProfile = { username in
            let cleanUsername = username.trimmingCharacters(
                in: CharacterSet(charactersIn: "@")
            )

            guard let encodedUsername = cleanUsername.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ),
            let url = URL(string: "https://github.com/\(encodedUsername)") else {
                return
            }

            UIApplication.shared.open(url)
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
