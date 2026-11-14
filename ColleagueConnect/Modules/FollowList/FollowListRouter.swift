
import UIKit

@MainActor
final class FollowListRouter: FollowListRouterInput {

    weak var viewController: UIViewController?

    private let networkClient: NetworkClientProtocol
    private let authService: AuthServiceProtocol
    private let favoriteStorage: FavoriteStorageServiceProtocol
    private let recentlyViewedStorage: RecentlyViewedStorageServiceProtocol
    private let followStatusStore: FollowStatusStoreProtocol

    init(
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        recentlyViewedStorage: RecentlyViewedStorageServiceProtocol,
        followStatusStore: FollowStatusStoreProtocol
    ) {
        self.networkClient = networkClient
        self.authService = authService
        self.favoriteStorage = favoriteStorage
        self.recentlyViewedStorage = recentlyViewedStorage
        self.followStatusStore = followStatusStore
    }

    static func createModule(
        username: String,
        type: FollowListType,
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol,
        favoriteStorage: FavoriteStorageServiceProtocol,
        recentlyViewedStorage: RecentlyViewedStorageServiceProtocol,
        followStatusStore: FollowStatusStoreProtocol
    ) -> FollowListViewController {

        let interactor = FollowListInteractor(
            networkClient: networkClient,
            authService: authService,
            followStatusStore: followStatusStore
        )

        let router = FollowListRouter(
            networkClient: networkClient,
            authService: authService,
            favoriteStorage: favoriteStorage,
            recentlyViewedStorage: recentlyViewedStorage,
            followStatusStore: followStatusStore
        )

        let presenter = FollowListPresenter(
            username: username,
            type: type,
            interactor: interactor,
            router: router,
            followStatusStore: followStatusStore
        )

        let viewController = FollowListViewController(
            type: type
        )

        viewController.presenter = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

    func openUserDetail(username: String) {
        guard let navigationController =
                viewController?.navigationController else {
            return
        }

        let detailViewController = UserDetailRouter.createModule(
            username: username,
            networkClient: networkClient,
            favoriteStorage: favoriteStorage,
            authService: authService,
            recentlyViewedStorage: recentlyViewedStorage,
            followStatusStore: followStatusStore
        )

        navigationController.pushViewController(
            detailViewController,
            animated: true
        )
    }
}
