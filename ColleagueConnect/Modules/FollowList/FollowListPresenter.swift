
import Foundation

@MainActor
final class FollowListPresenter: FollowListViewOutput {

    weak var view: FollowListViewInput?

    private let interactor: FollowListInteractorInput
    private let router: FollowListRouterInput
    private let followStatusStore: FollowStatusStoreProtocol

    private let username: String
    private let type: FollowListType

    private var users: [FollowListUserViewModel] = []

    private var loadTask: Task<Void, Never>?
    private var followObserver: NSObjectProtocol?

    private var nextPage = 1
    private var isLoadingPage = false
    private var hasMorePages = true

    private var hasAppeared = false
    private var needsRefresh = false
    private var generation = 0

    private let pageSize = 30

    private let listCache = FollowListCache.shared

    private var cacheKey: String {
        let session = followStatusStore.currentSessionVersion()
        return "\(session)|\(username.lowercased())|\(type.title)"
    }


    private var locallyAdded: [String: FollowListUserViewModel] = [:]
    private var locallyRemoved: Set<String> = []

    init(
        username: String,
        type: FollowListType,
        interactor: FollowListInteractorInput,
        router: FollowListRouterInput,
        followStatusStore: FollowStatusStoreProtocol
    ) {
        self.username = username
        self.type = type
        self.interactor = interactor
        self.router = router
        self.followStatusStore = followStatusStore

        followObserver = NotificationCenter.default.addObserver(
            forName: .githubFollowChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in

            let changedUsername = notification.userInfo?[
                "username"
            ] as? String

            let isFollowing = notification.userInfo?[
                "isFollowing"
            ] as? Bool

            let name = notification.userInfo?[
                "name"
            ] as? String

            let avatarURL = notification.userInfo?[
                "avatarURL"
            ] as? URL

            Task { @MainActor [weak self] in
                guard let self,
                      self.type == .following,
                      let changedUsername,
                      let isFollowing else {
                    return
                }

                self.applyFollowChange(
                    username: changedUsername,
                    isFollowing: isFollowing,
                    name: name,
                    avatarURL: avatarURL
                )
            }
        }
    }


    func viewDidLoad() {
        if let cached = listCache.entry(for: cacheKey) {
            users = cached.users
            nextPage = cached.nextPage
            hasMorePages = cached.hasMorePages

            reconcileKnownUnfollows()
            view?.displayUsers(users)

            if listCache.needsRefresh(for: cacheKey) {
                refreshUsers()
            }
        } else {
            loadNextPage()
        }
    }


    func viewWillAppear() {
        reconcileKnownUnfollows()

        if !hasAppeared {
            hasAppeared = true
            return
        }

        if needsRefresh {
            refreshUsers()
        }
    }

    func didReachEnd() {
        guard !needsRefresh else {
            return
        }

        loadNextPage()
    }

    private func reconcileKnownUnfollows() {
        guard type == .following else {
            return
        }

        var removed = Set<String>()

        for user in users {
            if followStatusStore.status(
                for: user.username
            ) == false {
                removed.insert(user.username.lowercased())
            }
        }

        guard !removed.isEmpty else {
            return
        }

        locallyRemoved.formUnion(removed)

        for key in removed {
            locallyAdded.removeValue(forKey: key)
        }

        users.removeAll {
            removed.contains($0.username.lowercased())
        }

        view?.displayUsers(users)
    }

    private func applyFollowChange(
        username: String,
        isFollowing: Bool,
        name: String?,
        avatarURL: URL?
    ) {
        let key = username.lowercased()

        needsRefresh = true

        if isFollowing {
            locallyRemoved.remove(key)

            guard !users.contains(where: {
                $0.username.lowercased() == key
            }) else {
                return
            }

            guard let avatarURL else {
                return
            }

            let cleanName = name?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            let model = FollowListUserViewModel(
                username: username,
                name: cleanName.flatMap {
                    $0.isEmpty ? nil : $0
                } ?? username,
                avatarURL: avatarURL
            )

            locallyAdded[key] = model
            users.insert(model, at: 0)

            view?.displayUsers(users)

        } else {
            locallyAdded.removeValue(forKey: key)
            locallyRemoved.insert(key)

            users.removeAll {
                $0.username.lowercased() == key
            }

            view?.displayUsers(users)
        }
        listCache.updateUsers(users, for: cacheKey)
    }

    private func refreshUsers() {
        generation += 1
        loadTask?.cancel()

        nextPage = 1
        isLoadingPage = false
        hasMorePages = true
        needsRefresh = false

        reconcileKnownUnfollows()
        loadNextPage()
    }

    private func loadNextPage() {
        guard !isLoadingPage,
              hasMorePages else {
            return
        }

        isLoadingPage = true

        let requestedPage = nextPage
        let isFirstPage = requestedPage == 1
        let requestGeneration = generation

        if isFirstPage && users.isEmpty {
            view?.displayLoading()
        }

        loadTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let fetched = try await interactor.fetchUsers(
                    username: username,
                    type: type,
                    page: requestedPage
                )

                try Task.checkCancellation()

                guard requestGeneration == generation else {
                    return
                }

                var result: [FollowListUserViewModel] = []
                var seenUsernames = Set<String>()

                if !isFirstPage {
                    result = users

                    seenUsernames = Set(
                        users.map {
                            $0.username.lowercased()
                        }
                    )
                }

                for user in fetched {
                    let key = user.username.lowercased()

                    if type == .following {
                        if locallyRemoved.contains(key) {
                            continue
                        }

                        if followStatusStore.status(
                            for: user.username
                        ) == false {
                            locallyRemoved.insert(key)
                            continue
                        }
                    }

                    guard seenUsernames.insert(key).inserted else {
                        continue
                    }

                    let trimmedName = user.name?
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )

                    let model = FollowListUserViewModel(
                        username: user.username,
                        name: trimmedName.flatMap {
                            $0.isEmpty ? nil : $0
                        } ?? user.username,
                        avatarURL: user.avatarURL
                    )

                    result.append(model)
                }

                if type == .following {
                    for key in locallyAdded.keys.sorted() {
                        guard let model = locallyAdded[key] else {
                            continue
                        }

                        guard !locallyRemoved.contains(key) else {
                            continue
                        }

                        guard followStatusStore.status(
                            for: model.username
                        ) != false else {
                            continue
                        }

                        if seenUsernames.insert(key).inserted {
                            result.insert(model, at: 0)
                        }
                    }

                    result.removeAll {
                        let key = $0.username.lowercased()

                        return locallyRemoved.contains(key) ||
                            followStatusStore.status(
                                for: $0.username
                            ) == false
                    }
                }


                users = result
                nextPage += 1
                hasMorePages = fetched.count == pageSize
                isLoadingPage = false

                listCache.saveFetched(
                    users: users,
                    nextPage: nextPage,
                    hasMorePages: hasMorePages,
                    for: cacheKey
                )
                listCache.updateUsers(users, for: cacheKey)

                view?.displayUsers(users)


            } catch is CancellationError {
                guard requestGeneration == generation else {
                    return
                }

                isLoadingPage = false

            } catch {
                guard !Task.isCancelled,
                      requestGeneration == generation else {
                    return
                }

                isLoadingPage = false

                if isFirstPage && users.isEmpty {
                    view?.displayError(
                        "Couldn't load \(type.title.lowercased()). Please try again."
                    )
                } else {
                    view?.displayPageError(
                        "Couldn't refresh users. Please try again."
                    )
                }
            }
        }
    }

    func didSelectUser(at index: Int) {
        guard users.indices.contains(index) else {
            return
        }

        router.openUserDetail(
            username: users[index].username
        )
    }

    deinit {
        if let followObserver {
            NotificationCenter.default.removeObserver(
                followObserver
            )
        }

        loadTask?.cancel()
    }
}
