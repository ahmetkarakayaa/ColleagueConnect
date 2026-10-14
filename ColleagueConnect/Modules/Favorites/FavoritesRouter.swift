
import UIKit

@MainActor
final class FavoritesRouter: FavoritesRouterInput {

    weak var viewController: UIViewController?

    static func createModule() -> UIViewController {
        let view = FavoritesViewController()
        let interactor = FavoritesInteractor()
        let router = FavoritesRouter()

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
            username: username
        )

        viewController?.navigationController?.pushViewController(
            detailViewController,
            animated: true
        )
    }
}
