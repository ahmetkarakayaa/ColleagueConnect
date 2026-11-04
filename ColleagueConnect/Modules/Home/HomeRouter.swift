

import UIKit

@MainActor
final class HomeRouter {

    static func createModule(
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol
    ) -> UIViewController {
        let interactor = HomeInteractor(
            networkClient: networkClient,
            authService: authService,
            favoriteStorage: favoriteStorage
        )

        let presenter = HomePresenter(interactor: interactor)
        let viewController = HomeViewController()

        viewController.presenter = presenter
        presenter.view = viewController

        return viewController
    }
}
