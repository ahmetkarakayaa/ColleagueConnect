
import Foundation

struct FavoriteUserViewModel: Hashable {
    let username: String
    let avatarURL: URL?
    let name: String?
    let bio: String?

    init(
        username: String,
        avatarURL: URL?,
        name: String? = nil,
        bio: String? = nil
    ) {
        self.username = username
        self.avatarURL = avatarURL
        self.name = name
        self.bio = bio
    }
}
