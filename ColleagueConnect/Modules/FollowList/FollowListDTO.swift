
import Foundation

struct FollowListDTO: Decodable {

    let login: String
    let avatarURL: URL

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }

    func toEntity() -> FollowListUserEntity {
        FollowListUserEntity(
            username: login,
            avatarURL: avatarURL
        )
    }
}
