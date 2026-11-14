
import Foundation

@MainActor
struct FollowListCacheEntry {
    var users: [FollowListUserViewModel]
    var nextPage: Int
    var hasMorePages: Bool
    var lastFetchedAt: Date
}

@MainActor
final class FollowListCache {

    static let shared = FollowListCache()

    private var entries: [String: FollowListCacheEntry] = [:]
    private let refreshInterval: TimeInterval = 60

    private init() {}

    func entry(for key: String) -> FollowListCacheEntry? {
        entries[key]
    }

    func needsRefresh(for key: String) -> Bool {
        guard let entry = entries[key] else {
            return true
        }

        return Date().timeIntervalSince(entry.lastFetchedAt) >= refreshInterval
    }

    func saveFetched(
        users: [FollowListUserViewModel],
        nextPage: Int,
        hasMorePages: Bool,
        for key: String
    ) {
        entries[key] = FollowListCacheEntry(
            users: users,
            nextPage: nextPage,
            hasMorePages: hasMorePages,
            lastFetchedAt: Date()
        )
    }

    func updateUsers(
        _ users: [FollowListUserViewModel],
        for key: String
    ) {
        guard var entry = entries[key] else {
            return
        }

        entry.users = users
        entries[key] = entry
    }

    func clear() {
        entries.removeAll()
    }
}
