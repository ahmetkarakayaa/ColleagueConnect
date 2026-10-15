import UIKit

@MainActor
final class FavoritesRouter: FavoritesRouterInput {

    weak var viewController: UIViewController?

    private let networkClient: NetworkClientProtocol
    private let favoriteStorage: FavoriteStorageServiceProtocol

    init(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol
    ) {
        self.networkClient = networkClient
        self.favoriteStorage = favoriteStorage
    }

    static func createModule(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol
    ) -> UIViewController {

        let view = FavoritesViewController()

        let interactor = FavoritesInteractor(
            favoriteService: favoriteStorage,
            networkClient: networkClient
        )

        let router = FavoritesRouter(
            networkClient: networkClient,
            favoriteStorage: favoriteStorage
        )

        let presenter = FavoritesPresenter(
            interactor: interactor,
            router: router
        )

        view.presenter = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

    func showUserDetail(username: String) {
        let detailViewController = UserDetailRouter.createModule(
            username: username,
            networkClient: networkClient,
            favoriteStorage: favoriteStorage
        )

        viewController?.navigationController?.pushViewController(
            detailViewController,
            animated: true
        )
    }
}
