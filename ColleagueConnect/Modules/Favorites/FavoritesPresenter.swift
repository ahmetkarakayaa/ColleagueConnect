
import Foundation

@MainActor
final class FavoritesPresenter: FavoritesViewOutput {

    weak var view: FavoritesViewInput?

    private let interactor: FavoritesInteractorInput
    private let router: FavoritesRouterInput

    private var allFavorites: [FavoriteUserViewModel] = []
    private var currentQuery = ""

    private var loadingTask: Task<Void, Never>?
    private var activeRequestID: UUID?

    private var sortOption: FavoritesSortOption = .newest
    private var lastRequestedUsernames: [String]?

    init(
        interactor: FavoritesInteractorInput,
        router: FavoritesRouterInput
    ) {
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        view?.displayEmpty()
    }

    func viewWillAppear() {
        loadFavorites()
    }

    func retryFavorites() {
        lastRequestedUsernames = nil
        loadFavorites()
    }

    func filterFavorites(query: String) {
        currentQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        displayFilteredFavorites()
    }

    func sortFavorites(by option: FavoritesSortOption) {
        sortOption = option
        displayFilteredFavorites()
    }

    func removeFavorite(username: String) {
        interactor.removeFavorite(username: username)

        allFavorites.removeAll {
            $0.username.caseInsensitiveCompare(
                username
            ) == .orderedSame
        }

        lastRequestedUsernames = nil

        loadFavorites()
    }

    func didSelectUser(_ user: FavoriteUserViewModel) {
        router.showUserDetail(
            username: user.username
        )
    }

    private func loadFavorites() {
        let usernames = interactor.getRecentFavorites(
            limit: Int.max
        )

        if activeRequestID == nil,
           lastRequestedUsernames == usernames {
            displayFilteredFavorites()
            return
        }

        loadingTask?.cancel()
        loadingTask = nil
        activeRequestID = nil

        lastRequestedUsernames = usernames

        guard !usernames.isEmpty else {
            allFavorites = []
            displayFilteredFavorites()
            return
        }

        var cachedUsers = Dictionary(
            allFavorites.map {
                ($0.username.lowercased(), $0)
            },
            uniquingKeysWith: { first, _ in first }
        )

        allFavorites = usernames.compactMap {
            cachedUsers[$0.lowercased()]
        }

        let missingUsernames = usernames.filter {
            cachedUsers[$0.lowercased()] == nil
        }

        if missingUsernames.isEmpty {
            displayFilteredFavorites()
            return
        }

        if allFavorites.isEmpty {
            view?.displayLoading()
        } else {
            displayFilteredFavorites()
        }

        let requestID = UUID()
        activeRequestID = requestID

        loadingTask = Task { [weak self] in
            guard let self else { return }

            let interactor = self.interactor
            var hasFailedRequests = false

            for startIndex in stride(
                from: 0,
                to: missingUsernames.count,
                by: 4
            ) {
                guard !Task.isCancelled,
                      activeRequestID == requestID else {
                    return
                }

                let endIndex = min(
                    startIndex + 4,
                    missingUsernames.count
                )

                await withTaskGroup(
                    of: FavoriteUserViewModel?.self
                ) { group in

                    for username in missingUsernames[
                        startIndex..<endIndex
                    ] {
                        group.addTask { @MainActor in
                            do {
                                try Task.checkCancellation()

                                let profile = try await interactor
                                    .fetchFavoriteUser(
                                        username: username
                                    )

                                try Task.checkCancellation()

                                return FavoriteUserViewModel(
                                    username: profile.username,
                                    avatarURL: profile.avatarURL,
                                    name: profile.name,
                                    bio: profile.bio
                                )

                            } catch {
                                return nil
                            }
                        }
                    }

                    for await fetchedUser in group {
                        guard !Task.isCancelled,
                              activeRequestID == requestID else {
                            continue
                        }

                        guard let fetchedUser else {
                            hasFailedRequests = true
                            continue
                        }

                        let key = fetchedUser.username.lowercased()

                        cachedUsers[key] = fetchedUser

                        let currentUsernames =
                            interactor.getRecentFavorites(
                                limit: Int.max
                            )

                        allFavorites = currentUsernames.compactMap {
                            cachedUsers[$0.lowercased()]
                        }

                        displayFilteredFavorites()
                    }
                }
            }

            guard !Task.isCancelled,
                  activeRequestID == requestID else {
                return
            }

            activeRequestID = nil
            loadingTask = nil

            let finalUsernames = interactor.getRecentFavorites(
                limit: Int.max
            )

            allFavorites = finalUsernames.compactMap {
                cachedUsers[$0.lowercased()]
            }

            if allFavorites.isEmpty,
               !finalUsernames.isEmpty,
               hasFailedRequests {
                view?.displayError(
                    "Couldn't load favorites. Please try again."
                )
            } else {
                displayFilteredFavorites()
            }

            if hasFailedRequests {
                lastRequestedUsernames = nil
            }
        }
    }

    private func displayFilteredFavorites() {
        let storedFavorites = interactor.getFavorites()

        guard !storedFavorites.isEmpty else {
            if currentQuery.isEmpty {
                view?.displayEmpty()
            } else {
                view?.displayNoResults()
            }
            return
        }

        let filteredUsers = allFavorites.filter { user in
            currentQuery.isEmpty ||
            user.username.localizedCaseInsensitiveContains(
                currentQuery
            )
        }

        let sortedUsers: [FavoriteUserViewModel]

        switch sortOption {
        case .newest:
            sortedUsers = filteredUsers

        case .oldest:
            sortedUsers = Array(
                filteredUsers.reversed()
            )

        case .alphabetical:
            sortedUsers = filteredUsers.sorted {
                $0.username.localizedCaseInsensitiveCompare(
                    $1.username
                ) == .orderedAscending
            }

        case .reverseAlphabetical:
            sortedUsers = filteredUsers.sorted {
                $0.username.localizedCaseInsensitiveCompare(
                    $1.username
                ) == .orderedDescending
            }
        }

        if sortedUsers.isEmpty {
            if activeRequestID != nil,
               currentQuery.isEmpty {
                view?.displayLoading()
            } else {
                view?.displayNoResults()
            }
        } else {
            view?.displayFavorites(sortedUsers)
        }
    }

    deinit {
        loadingTask?.cancel()
    }
}
