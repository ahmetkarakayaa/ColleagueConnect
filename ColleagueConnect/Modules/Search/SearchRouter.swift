
import UIKit

@MainActor
final class SearchRouter: SearchRouterInput {

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

        let view = SearchViewController()

        let interactor = SearchInteractor(
            networkClient: networkClient,
            favoriteService: favoriteStorage
        )

        let router = SearchRouter(
            networkClient: networkClient,
            favoriteStorage: favoriteStorage
        )

        let presenter = SearchPresenter(
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
