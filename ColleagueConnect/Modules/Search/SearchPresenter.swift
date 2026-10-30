
import Foundation
import OSLog

@MainActor
final class SearchPresenter: SearchViewOutput {

    weak var view: SearchViewInput?

    private let interactor: SearchInteractorInput
    private let router: SearchRouterInput
    private let favoriteService: FavoriteStorageServiceProtocol
    private let logger = Logger(
        subsystem: "ColleagueConnect",
        category: "SearchPresenter"
    )


    private var searchTask: Task<Void, Never>?

    private var detailTasks: [String: Task<Void, Never>] = [:]


    private struct CachedProfile {
        let name: String?
        let bio: String?
    }

    private var profileCache: [String: CachedProfile] = [:]

    
    init(
        interactor: SearchInteractorInput,
        router: SearchRouterInput,
        favoriteService: FavoriteStorageServiceProtocol
    ) {
        self.interactor = interactor
        self.router = router
        self.favoriteService = favoriteService
    }


    func searchUsers(query: String) {
        searchTask?.cancel()

        detailTasks.values.forEach { $0.cancel() }
        detailTasks.removeAll()

        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedQuery.isEmpty else {
            view?.displayEmpty()
            return
        }

        searchTask = Task {
            do {
                try await Task.sleep(
                    nanoseconds: 350_000_000
                )

                try Task.checkCancellation()

                view?.displayLoading()

                
                
                let response = try await interactor.searchUsers(
                    query: trimmedQuery
                )

                try Task.checkCancellation()

                let viewModels = response.items.map { user in
                    SearchUserViewModel(
                        id: user.id,
                        username: user.login,
                        avatarURL: user.avatarURL
                    )
                }



                if viewModels.isEmpty {
                    view?.displayEmpty()
                } else {
                    view?.displayUsers(viewModels)
                }

            } catch is CancellationError {
                return

            } catch {
                guard !Task.isCancelled else { return }

                
                if case NetworkError.offline = error {
                    view?.displayError(.offline)
                } else {
                    view?.displayError(.general)
                }

            }
        }
    }


    func loadUserDetails(username: String) {

        if let cached = profileCache[username] {
            view?.displayUserDetails(
                username: username,
                name: cached.name,
                bio: cached.bio
            )
            return
        }

        guard detailTasks[username] == nil else {
            return
        }

        detailTasks[username] = Task {
            defer {
                detailTasks[username] = nil
            }

            do {
                let detail = try await interactor.fetchUserDetails(
                    username: username
                )

                try Task.checkCancellation()

                let profile = CachedProfile(
                    name: detail.name,
                    bio: detail.bio
                )

                profileCache[username] = profile

                view?.displayUserDetails(
                    username: username,
                    name: detail.name,
                    bio: detail.bio
                )

            
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }

                logger.error(
                    "Failed to load details for \(username): \(error.localizedDescription)"
                )
            }

    }
}

    func didSelectUser(
        _ user: SearchUserViewModel
    ) {
        router.showUserDetail(
            username: user.username
        )
    }
    
    func toggleFavorite(username: String) {
        if favoriteService.isFavorite(username: username) {
            favoriteService.removeFavorite(username: username)
        } else {
            favoriteService.addFavorite(username: username)
        }
    }

    func isFavorite(username: String) -> Bool {
        favoriteService.isFavorite(username: username)
    }



    
}
