import UIKit

@MainActor
final class HomeRouter {

    static func createModule(
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        recentlyViewedStorage: RecentlyViewedStorageServiceProtocol
    ) -> HomeViewController {
        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: authService,
            favoriteStorage: favoriteStorage,
            recentlyViewedStorage: recentlyViewedStorage
        )

        let presenter = HomePresenter(interactor: interactor)
        let viewController = HomeViewController()

        viewController.presenter = presenter
        presenter.view = viewController

        return viewController
    }
}
