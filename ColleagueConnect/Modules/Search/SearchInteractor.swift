
import Foundation

final class SearchInteractor: SearchInteractorInput {

    private let networkClient: NetworkClientProtocol

    
    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }



    
    func searchUsers(query: String) async throws -> GitHubSearchResponse {
        try await networkClient.request(
            endpoint: GitHubEndpoint.searchUsers(query: query)
        )
    }

    


    func fetchUserDetails(
        username: String
    ) async throws -> UserDetailEntity {
        let dto: UserDetailDTO = try await networkClient.request(
            endpoint: GitHubEndpoint.userDetail(username: username)
        )
        return dto.toEntity()
    }


    
}
