import UIKit

@MainActor
final class FavoritesRouter: FavoritesRouterInput {

    weak var viewController: UIViewController?

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


    static func createModule(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        authService: AuthServiceProtocol
    ) -> UIViewController {
        let view = FavoritesViewController()

        let interactor = FavoritesInteractor(
            favoriteService: favoriteStorage,
            networkClient: networkClient,
            authService: authService
        )

        let router = FavoritesRouter(
            networkClient: networkClient,
            favoriteStorage: favoriteStorage,
            authService: authService
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
