
import Foundation

enum OAuthConfigurationError: Error {
    case missingClientID
    case missingClientSecret
}

struct OAuthConfiguration {
    let clientID: String
    let clientSecret: String
    let redirectURI: String

    init(clientID: String, clientSecret: String, redirectURI: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
    }


    init(bundle: Bundle = .main) throws {
        guard let clientID = bundle.object(
            forInfoDictionaryKey: "GITHUB_CLIENT_ID"
        ) as? String,
        !clientID.isEmpty,
        !clientID.hasPrefix("$(") else {
            throw OAuthConfigurationError.missingClientID
        }

        guard let clientSecret = bundle.object(
            forInfoDictionaryKey: "GITHUB_CLIENT_SECRET"
        ) as? String,
        !clientSecret.isEmpty,
        !clientSecret.hasPrefix("$(") else {
            throw OAuthConfigurationError.missingClientSecret
        }

        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = "colleagueconnect://auth"
    }
}
