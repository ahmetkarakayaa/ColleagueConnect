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

    func filterFavorites(query: String) {
        currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // Do not replace a loading/error state while no profiles are loaded.
        guard activeRequestID == nil else { return }
        displayFilteredFavorites()
    }

    func removeFavorite(username: String) {
        interactor.removeFavorite(username: username)
        allFavorites.removeAll {
            $0.username.caseInsensitiveCompare(username) == .orderedSame
        }

        // A pending response may have started before the favorite was removed.
        // Cancel it and reload the remaining saved users instead of showing stale data.
        if activeRequestID != nil {
            loadFavorites()
        } else {
            displayFilteredFavorites()
        }
    }

    func didSelectUser(_ user: FavoriteUserViewModel) {
        router.showUserDetail(username: user.username)
    }

    private func loadFavorites() {
        loadingTask?.cancel()
        activeRequestID = nil

        if interactor.getFavorites().isEmpty {
            loadingTask = nil
            allFavorites = []
            displayFilteredFavorites()
            return
        }

        let requestID = UUID()
        activeRequestID = requestID
        view?.displayLoading()

        loadingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let users = try await interactor.fetchFavoriteUsers()
                guard !Task.isCancelled, activeRequestID == requestID else { return }

                activeRequestID = nil
                loadingTask = nil
                allFavorites = users
                displayFilteredFavorites()
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, activeRequestID == requestID else { return }
                activeRequestID = nil
                loadingTask = nil
                view?.displayError("Favoriler yüklenemedi. Lütfen tekrar deneyin.")
            }
        }
    }

    private func displayFilteredFavorites() {
        // Empty saved list and no matching search results are different states.
        guard !interactor.getFavorites().isEmpty else {
            view?.displayEmpty()
            return
        }

        let filteredUsers = allFavorites.filter { user in
            currentQuery.isEmpty ||
            user.username.localizedCaseInsensitiveContains(currentQuery)
        }

        if filteredUsers.isEmpty {
            view?.displayNoResults()
        } else {
            view?.displayFavorites(filteredUsers)
        }
    }
}
