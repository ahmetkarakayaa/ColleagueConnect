
import Foundation

@MainActor
final class HomePresenter: HomeViewOutput {

    weak var view: HomeViewInput?

    private let interactor: HomeInteractorInput
    private var loadTask: Task<Void, Never>?
    private var favoritesTask: Task<Void, Never>?
    private var recentlyViewedTask: Task<Void, Never>?
    private var retryObserver: NSObjectProtocol?
    

    
    init(interactor: HomeInteractorInput) {
        self.interactor = interactor

        retryObserver = NotificationCenter.default.addObserver(
            forName: AppInternetMonitor.retryNotification,            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.retryAll()
            }
        }
    }


    func viewDidLoad() {
        loadProfile()
    }

    func viewWillAppear() {
        loadFavorites()
        loadRecentlyViewed()
    }
    
    func didTapRetry() {
        loadProfile()
    }

    
    private func retryAll() {
        loadProfile()
        loadFavorites()
        loadRecentlyViewed()
    }


    private func loadFavorites() {
        favoritesTask?.cancel()

        favoritesTask = Task { [weak self] in
            guard let self else { return }

            do {
                let snapshot = try await interactor.fetchFavorites()

                guard !Task.isCancelled else { return }

                let recentUsers = snapshot.recentUsers.map { user in
                    HomeRecentFavoriteViewModel(
                        username: user.username,
                        name: user.name?.isEmpty == false
                            ? user.name!
                            : user.username,
                        avatarURL: user.avatarURL
                    )
                }

                let model = HomeFavoritesViewModel(
                    totalCount: snapshot.totalCount.formatted(),
                    recentUsers: recentUsers
                )

                view?.displayFavorites(model)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }

                view?.displayFavorites(
                    HomeFavoritesViewModel(
                        totalCount: "—",
                        recentUsers: []
                    )
                )
            }
        }
    }
    private func loadRecentlyViewed() {
        recentlyViewedTask?.cancel()

        recentlyViewedTask = Task { [weak self] in
            guard let self else { return }

            do {
                let profiles = try await interactor.fetchRecentlyViewed()
                guard !Task.isCancelled else { return }

                let users = profiles.map { user in
                    HomeRecentFavoriteViewModel(
                        username: user.username,
                        name: user.name?.isEmpty == false
                            ? user.name!
                            : user.username,
                        avatarURL: user.avatarURL
                    )
                }

                view?.displayRecentlyViewed(users)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                view?.displayRecentlyViewed([])
            }
        }
    }

    private func loadProfile() {
        loadTask?.cancel()
        view?.displayLoading()

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let user = try await interactor.fetchCurrentUser()

                guard !Task.isCancelled else { return }

                let model = HomeViewModel(
                    name: user.name ?? user.login,
                    username: "@\(user.login)",
                    bio: user.bio,
                    avatarURL: user.avatarURL,
                    followers: user.followers.formatted(),
                    following: user.following.formatted(),
                    profileURL: user.htmlURL
                )

                view?.displayProfile(model)
            } catch {
                guard !Task.isCancelled else { return }

                view?.displayError(
                    "Couldn't load your profile. Please try again."
                )
            }
        }
    }

    
    deinit {
        if let retryObserver {
            NotificationCenter.default.removeObserver(retryObserver)
        }

        loadTask?.cancel()
        favoritesTask?.cancel()
        recentlyViewedTask?.cancel()
    }

}
