import Foundation

protocol RecentlyViewedStorageServiceProtocol {
    func recordVisit(username: String)
    func getRecentlyViewed(limit: Int?) -> [String]
    func clearHistory()
}

final class RecentlyViewedStorageService: RecentlyViewedStorageServiceProtocol {

    private let defaults: UserDefaults
    private let storageKey = "recently_viewed_usernames"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recordVisit(username: String) {
        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else { return }

        var usernames = getRecentlyViewed(limit: nil)
        usernames.removeAll {
            $0.caseInsensitiveCompare(username) == .orderedSame
        }
        usernames.insert(username, at: 0)

        defaults.set(usernames, forKey: storageKey)
    }

    func getRecentlyViewed(limit: Int? = nil) -> [String] {
        let usernames = defaults.stringArray(forKey: storageKey) ?? []

        guard let limit else { return usernames }
        return Array(usernames.prefix(max(0, limit)))
    }

    func clearHistory() {
        defaults.removeObject(forKey: storageKey)
    }
}
