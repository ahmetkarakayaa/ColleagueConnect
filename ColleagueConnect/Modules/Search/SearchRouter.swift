
import UIKit

@MainActor
final class SearchRouter: SearchRouterInput {

    weak var viewController: UIViewController?

    private let makeUserDetail: @MainActor (String) -> UIViewController

    init(
        makeUserDetail: @escaping @MainActor (String) -> UIViewController
    ) {
        self.makeUserDetail = makeUserDetail
    }

    static func createModule(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol
    ) -> UIViewController {

        let view = SearchViewController()

        let interactor = SearchInteractor(
            networkClient: networkClient
        )

        let router = SearchRouter(makeUserDetail: { username in
            UserDetailRouter.createModule(
                username: username,
                networkClient: networkClient,
                favoriteStorage: favoriteStorage
            )
        })

        let presenter = SearchPresenter(
            interactor: interactor,
            router: router,
            favoriteService: favoriteStorage
        )

        view.presenter = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

    func showUserDetail(username: String) {
        let detailViewController = makeUserDetail(username)

        viewController?.navigationController?.pushViewController(
            detailViewController,
            animated: true
        )
    }
}
