
import Foundation

@MainActor
final class HomePresenter: HomeViewOutput {

    weak var view: HomeViewInput?

    private let interactor: HomeInteractorInput

    private var loadTask: Task<Void, Never>?
    private var favoritesTask: Task<Void, Never>?
    private var recentlyViewedTask: Task<Void, Never>?

    private var retryObserver: NSObjectProtocol?
    private var followObserver: NSObjectProtocol?

    private var lastRetryTime: Date?
    private var hasAppeared = false

    private var currentProfile: HomeViewModel?
    private var currentFollowingCount: Int?
    private var pendingFollowingCount: Int?
    private var lastFollowChange: Date?

    init(interactor: HomeInteractorInput) {
        self.interactor = interactor

        retryObserver = NotificationCenter.default.addObserver(
            forName: AppInternetMonitor.retryNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.retryAll()
            }
        }

        followObserver = NotificationCenter.default.addObserver(
            forName: .githubFollowChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in

            let isFollowing = notification.userInfo?[
                "isFollowing"
            ] as? Bool

            Task { @MainActor [weak self] in
                guard let self,
                      let isFollowing else {
                    return
                }

                self.applyFollowChange(
                    isFollowing: isFollowing
                )
            }
        }
    }

    func viewDidLoad() {
        loadProfile()
    }

    func viewWillAppear() {
        if hasAppeared {
            loadProfile(showLoading: false)
        } else {
            hasAppeared = true
        }

        loadFavorites()
        loadRecentlyViewed()
    }

    func didTapRetry() {
        loadProfile()
    }

    private func retryAll() {
        let now = Date()

        if let lastRetryTime,
           now.timeIntervalSince(lastRetryTime) < 3 {
            return
        }

        lastRetryTime = now

        loadProfile(showLoading: false)
        loadFavorites()
        loadRecentlyViewed()
    }

    private func applyFollowChange(
        isFollowing: Bool
    ) {
        guard let profile = currentProfile,
              let count = currentFollowingCount else {
            loadProfile(showLoading: false)
            return
        }

        let updatedCount = max(
            0,
            count + (isFollowing ? 1 : -1)
        )

        currentFollowingCount = updatedCount
        pendingFollowingCount = updatedCount
        lastFollowChange = Date()

        let updatedProfile = HomeViewModel(
            name: profile.name,
            username: profile.username,
            bio: profile.bio,
            avatarURL: profile.avatarURL,
            followers: profile.followers,
            following: updatedCount.formatted(),
            profileURL: profile.profileURL
        )

        currentProfile = updatedProfile
        view?.displayProfile(updatedProfile)
    }

    private func loadProfile(
        showLoading: Bool = true
    ) {
        loadTask?.cancel()

        if showLoading {
            view?.displayLoading()
        }

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let user = try await interactor.fetchCurrentUser()

                try Task.checkCancellation()

                let serverFollowing = user.following
                let followingCount: Int

                if let pendingFollowingCount,
                   let lastFollowChange,
                   Date().timeIntervalSince(lastFollowChange) < 15,
                   serverFollowing != pendingFollowingCount {

                    followingCount = pendingFollowingCount

                } else {
                    followingCount = serverFollowing
                    self.pendingFollowingCount = nil
                    self.lastFollowChange = nil
                }

                currentFollowingCount = followingCount

                let model = HomeViewModel(
                    name: user.name ?? user.login,
                    username: "@\(user.login)",
                    bio: user.bio,
                    avatarURL: user.avatarURL,
                    followers: user.followers.formatted(),
                    following: followingCount.formatted(),
                    profileURL: user.htmlURL
                )

                currentProfile = model
                view?.displayProfile(model)

            } catch is CancellationError {
                return

            } catch {
                guard !Task.isCancelled else { return }

                if showLoading {
                    view?.displayError(
                        "Couldn't load your profile. Please try again."
                    )
                }
            }
        }
    }

    private func loadFavorites() {
        favoritesTask?.cancel()

        favoritesTask = Task { [weak self] in
            guard let self else { return }

            do {
                let snapshot = try await interactor.fetchFavorites()

                try Task.checkCancellation()

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

                try Task.checkCancellation()

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

    deinit {
        if let retryObserver {
            NotificationCenter.default.removeObserver(
                retryObserver
            )
        }

        if let followObserver {
            NotificationCenter.default.removeObserver(
                followObserver
            )
        }

        loadTask?.cancel()
        favoritesTask?.cancel()
        recentlyViewedTask?.cancel()
    }
}
