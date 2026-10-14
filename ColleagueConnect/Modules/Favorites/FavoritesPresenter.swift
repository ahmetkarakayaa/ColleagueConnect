
import Foundation

@MainActor
final class FavoritesPresenter: FavoritesViewOutput {

    weak var view: FavoritesViewInput?

    private let interactor: FavoritesInteractorInput
    private let router: FavoritesRouterInput

    private var allFavorites: [FavoriteUserViewModel] = []
    private var currentQuery = ""
    private var loadingTask: Task<Void, Never>?

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
        currentQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        displayFilteredFavorites()
    }

    func removeFavorite(username: String) {
        interactor.removeFavorite(username: username)

        allFavorites.removeAll {
            $0.username == username
        }

        displayFilteredFavorites()
    }

    func didSelectUser(_ user: FavoriteUserViewModel) {
        router.showUserDetail(username: user.username)
    }

    private func loadFavorites() {
        loadingTask?.cancel()

        if interactor.getFavorites().isEmpty {
            allFavorites = []
            displayFilteredFavorites()
            return
        }

        view?.displayLoading()

        loadingTask = Task {
            do {
                let users = try await interactor.fetchFavoriteUsers()

                guard !Task.isCancelled else { return }

                allFavorites = users
                displayFilteredFavorites()

            } catch {
                guard !Task.isCancelled else { return }

                view?.displayError(
                    "Favoriler yüklenemedi. Lütfen tekrar deneyin."
                )
            }
        }
    }

    private func displayFilteredFavorites() {
        let filteredUsers = allFavorites.filter { user in
            currentQuery.isEmpty ||
            user.username.localizedCaseInsensitiveContains(
                currentQuery
            )
        }

        if filteredUsers.isEmpty {
            view?.displayEmpty()
        } else {
            view?.displayFavorites(filteredUsers)
        }
    }
}
