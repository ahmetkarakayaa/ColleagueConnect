
import Foundation

struct FollowListUserEntity {

    let username: String
    let avatarURL: URL
    let name: String?

    init(
        username: String,
        avatarURL: URL,
        name: String? = nil
    ) {
        self.username = username
        self.avatarURL = avatarURL
        self.name = name
    }
}
