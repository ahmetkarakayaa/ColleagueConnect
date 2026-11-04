
import Foundation

@MainActor
final class HomePresenter: HomeViewOutput {

    weak var view: HomeViewInput?

    private let interactor: HomeInteractorInput
    private var loadTask: Task<Void, Never>?
    private var favoritesTask: Task<Void, Never>?

    init(interactor: HomeInteractorInput) {
        self.interactor = interactor
    }


    func viewDidLoad() {
        loadProfile()
    }

    func viewWillAppear() {
        loadFavorites()
    }

    func didTapRetry() {
        loadProfile()
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
        loadTask?.cancel()
        favoritesTask?.cancel()
    }
}
