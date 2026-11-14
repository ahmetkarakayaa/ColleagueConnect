
import UIKit

@MainActor
final class FavoritesRouter: FavoritesRouterInput {

    weak var viewController: UIViewController?

    private let networkClient: NetworkClientProtocol
    private let favoriteStorage: FavoriteStorageServiceProtocol
    private let authService: AuthServiceProtocol
    private let recentlyViewedStorage: RecentlyViewedStorageServiceProtocol
    private let followStatusStore: FollowStatusStoreProtocol

    init(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        authService: AuthServiceProtocol,
        recentlyViewedStorage: RecentlyViewedStorageServiceProtocol,
        followStatusStore: FollowStatusStoreProtocol
    ) {
        self.networkClient = networkClient
        self.favoriteStorage = favoriteStorage
        self.authService = authService
        self.recentlyViewedStorage = recentlyViewedStorage
        self.followStatusStore = followStatusStore
    }

    static func createModule(
        networkClient: NetworkClientProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        authService: AuthServiceProtocol,
        recentlyViewedStorage: RecentlyViewedStorageServiceProtocol,
        followStatusStore: FollowStatusStoreProtocol
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
            authService: authService,
            recentlyViewedStorage: recentlyViewedStorage,
            followStatusStore: followStatusStore
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
            favoriteStorage: favoriteStorage,
            authService: authService,
            recentlyViewedStorage: recentlyViewedStorage,
            followStatusStore: followStatusStore
        )

        viewController?.navigationController?.pushViewController(
            detailViewController,
            animated: true
        )
    }
}
