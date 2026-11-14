
import Foundation

@MainActor
final class UserDetailPresenter: UserDetailViewOutput {

    weak var view: UserDetailViewInput?

    private let interactor: UserDetailInteractorInput
    private let router: UserDetailRouterInput
    private let username: String

    private var user: UserDetailEntity?

    private var isFollowing = false
    private var isFollowStateLoaded = false
    private var isFollowLoading = false

    private var loadTask: Task<Void, Never>?
    private var followCheckTask: Task<Void, Never>?
    private var followTask: Task<Void, Never>?

    init(
        username: String,
        interactor: UserDetailInteractorInput,
        router: UserDetailRouterInput
    ) {
        self.username = username
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        loadFollowingStatus()
        loadUser()
    }

    private func loadUser() {
        loadTask?.cancel()
        view?.displayLoading()

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let fetchedUser = try await interactor.fetchUser(
                    username: username
                )

                try Task.checkCancellation()

                user = fetchedUser

                view?.displayUser(
                    fetchedUser,
                    isFavorite: interactor.isFavorite(
                        username: fetchedUser.login
                    )
                )

                updateFollowState()

            } catch is CancellationError {
                return

            } catch {
                guard !Task.isCancelled else { return }

                view?.displayError(
                    "Couldn't load this profile. Please try again."
                )
            }
        }
    }


    private func loadFollowingStatus() {
        followCheckTask?.cancel()

        let cachedStatus = interactor.cachedFollowStatus(
            username: username
        )

        if let cachedStatus {
            isFollowing = cachedStatus
            isFollowStateLoaded = true
            isFollowLoading = false
            updateFollowState()

            guard interactor.shouldRefreshFollowStatus(
                username: username
            ) else {
                return
            }
        } else {
            isFollowStateLoaded = false
            isFollowLoading = true
            updateFollowState()
        }

        followCheckTask = Task { [weak self] in
            guard let self else { return }

            do {
                let result = try await interactor.isFollowing(
                    username: username
                )

                try Task.checkCancellation()

                guard !isFollowLoading || cachedStatus == nil else {
                    return
                }

                isFollowing = result
                isFollowStateLoaded = true
                isFollowLoading = false
                updateFollowState()

            } catch is CancellationError {
                return

            } catch {
                guard !Task.isCancelled else { return }

                if cachedStatus == nil {
                    isFollowStateLoaded = false
                    isFollowLoading = false
                    updateFollowState()

                    view?.displayFollowError(
                        "Couldn't check follow status. Please try again."
                    )
                }
            }
        }
    }

    func didTapFollow() {
        guard let user,
              isFollowStateLoaded,
              !isFollowLoading,
              !isFollowing else {
            return
        }

        performFollowAction(
            username: user.login,
            shouldFollow: true
        )
    }

    func didTapUnfollow() {
        guard let user,
              isFollowStateLoaded,
              !isFollowLoading,
              isFollowing else {
            return
        }

        performFollowAction(
            username: user.login,
            shouldFollow: false
        )
    }

    private func performFollowAction(
        username: String,
        shouldFollow: Bool
    ) {
        guard isFollowStateLoaded,
              !isFollowLoading else {
            return
        }

        let previousState = isFollowing

        isFollowing = shouldFollow
        isFollowLoading = true

        view?.displayFollowState(
            isFollowing: shouldFollow,
            isLoading: true,
            isAvailable: true
        )

        followTask = Task { [weak self] in
            guard let self else { return }

            do {
                if shouldFollow {
                    try await interactor.followUser(
                        username: username
                    )
                } else {
                    try await interactor.unfollowUser(
                        username: username
                    )
                }

                try Task.checkCancellation()

                isFollowLoading = false
                updateFollowState()

                NotificationCenter.default.post(
                    name: .githubFollowChanged,
                    object: nil,
                    userInfo: [
                        "username": username,
                        " isFollowing": shouldFollow,
                        "name": user?.name ?? username,
                        "avatarURL": user?.avatarURL as Any
                    ]
                )


            } catch is CancellationError {
                isFollowing = previousState
                isFollowLoading = false
                updateFollowState()

            } catch {
                isFollowing = previousState
                isFollowLoading = false
                updateFollowState()

                guard !Task.isCancelled else { return }

                view?.displayFollowError(
                    "Couldn't update follow status. Please try again."
                )
            }
        }
    }

    private func updateFollowState() {
        view?.displayFollowState(
            isFollowing: isFollowing,
            isLoading: isFollowLoading,
            isAvailable: isFollowStateLoaded
        )
    }

    func didTapFavorite() {
        guard let user else { return }

        let isFavorite = interactor.toggleFavorite(
            username: user.login
        )

        view?.displayUser(
            user,
            isFavorite: isFavorite
        )

        updateFollowState()
    }

    func didTapGitHub() {
        guard let user else { return }

        router.openGitHubProfile(user.htmlURL)
    }


    deinit {
        loadTask?.cancel()
        followCheckTask?.cancel()
    }

}
