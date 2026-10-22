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
        currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard activeRequestID == nil else { return }

        displayFilteredFavorites()
    }
    func sortFavorites(by option: FavoritesSortOption) {
        sortOption = option

        guard activeRequestID == nil else { return }

        displayFilteredFavorites()
    }

    
    func removeFavorite(username: String) {
        interactor.removeFavorite(username: username)

        allFavorites.removeAll {
            $0.username.caseInsensitiveCompare(username) == .orderedSame
        }

        if activeRequestID != nil {
            loadFavorites()
        } else {
            lastRequestedUsernames = interactor.getFavorites()
            displayFilteredFavorites()
        }
    }


    func didSelectUser(_ user: FavoriteUserViewModel) {
        router.showUserDetail(username: user.username)
    }

   
    
    
    private func loadFavorites() {
        let usernames = interactor.getFavorites()

        if activeRequestID == nil,
           lastRequestedUsernames == usernames {
            if !allFavorites.isEmpty || usernames.isEmpty {
                displayFilteredFavorites()
            }
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

        let cachedUsers = Dictionary(
            allFavorites.map {
                ($0.username.lowercased(), $0)
            },
            uniquingKeysWith: { first, _ in first }
        )

        let missingUsernames = usernames.enumerated().compactMap { index, username
            -> (Int, String)? in

            cachedUsers[username.lowercased()] == nil
                ? (index, username)
                : nil
        }

        if missingUsernames.isEmpty {
            allFavorites = usernames.compactMap {
                cachedUsers[$0.lowercased()]
            }
            displayFilteredFavorites()
            return
        }

        let requestID = UUID()
        activeRequestID = requestID
        view?.displayLoading()

        loadingTask = Task { [weak self] in
            guard let self else { return }

            let interactor = self.interactor
            var fetchedUsers: [FavoriteUserViewModel] = []

            for startIndex in stride(
                from: 0,
                to: missingUsernames.count,
                by: 4
            ) {
                guard !Task.isCancelled else { return }

                let endIndex = min(
                    startIndex + 4,
                    missingUsernames.count
                )

                let batch = await withTaskGroup(
                    of: FavoriteUserViewModel?.self,
                    returning: [FavoriteUserViewModel].self
                ) { group in

                    for item in missingUsernames[startIndex..<endIndex] {
                        let username = item.1

                        group.addTask { @MainActor in
                            do {
                                try Task.checkCancellation()

                                let profile = try await interactor.fetchFavoriteUser(
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

                    var successfulUsers: [FavoriteUserViewModel] = []

                    for await user in group {
                        if let user {
                            successfulUsers.append(user)
                        }
                    }

                    return successfulUsers
                }

                guard !Task.isCancelled else { return }

                fetchedUsers.append(contentsOf: batch)
            }

            guard !Task.isCancelled,
                  activeRequestID == requestID else {
                return
            }

            activeRequestID = nil
            loadingTask = nil

            let combinedUsers = cachedUsers.merging(
                Dictionary(
                    fetchedUsers.map {
                        ($0.username.lowercased(), $0)
                    },
                    uniquingKeysWith: { first, _ in first }
                ),
                uniquingKeysWith: { _, new in new }
            )

            allFavorites = usernames.compactMap {
                combinedUsers[$0.lowercased()]
            }

            if allFavorites.isEmpty {
                view?.displayError(
                    "Couldn't load favorites. Please try again."
                )
            } else {
                displayFilteredFavorites()
            }
        }
    }




    private func displayFilteredFavorites() {
        guard !interactor.getFavorites().isEmpty else {
            view?.displayEmpty()
            return
        }

        let filteredUsers = allFavorites.filter { user in
            currentQuery.isEmpty ||
            user.username.localizedCaseInsensitiveContains(currentQuery)
        }

        let sortedUsers: [FavoriteUserViewModel]

        switch sortOption {
        case .newest:
            sortedUsers = filteredUsers

        case .oldest:
            sortedUsers = Array(filteredUsers.reversed())

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
            view?.displayNoResults()
        } else {
            view?.displayFavorites(sortedUsers)
        }
    }}
