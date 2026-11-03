
import Foundation

struct HomeRecentFavoriteViewModel {
    let username: String
    let name: String
    let avatarURL: URL?
}

struct HomeFavoritesViewModel {
    let totalCount: String
    let recentUsers: [HomeRecentFavoriteViewModel]
}
