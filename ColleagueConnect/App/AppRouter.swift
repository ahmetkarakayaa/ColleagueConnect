
import UIKit

@MainActor
final class AppRouter {

    func makeInitialViewController() -> UIViewController {

        let searchViewController = SearchRouter.createModule()
        let favoritesViewController = FavoritesRouter.createModule()

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

        let n11Image = UIImage(named: "N11TabIcon")?
            .withRenderingMode(.alwaysOriginal)

        favoritesNavigation.tabBarItem = UITabBarItem(
            title: "Favorites",
            image: UIImage(
                systemName: "heart",
                withConfiguration: iconConfig
            ),
            selectedImage: n11Image
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
