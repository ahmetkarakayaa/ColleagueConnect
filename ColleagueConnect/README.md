# ColleagueConnect

ColleagueConnect is an iOS application built with UIKit and VIPER architecture. It uses the GitHub REST API to provide user search, profile details, and favourites management.

## Technologies

- Swift
- UIKit with programmatic Auto Layout
- VIPER architecture
- URLSession with async/await
- GitHub REST API and OAuth 2.0
- KeychainSwift for secure token storage
- Kingfisher for image loading
- XCTest for unit testing
- Swift Package Manager

## Project Setup

1. Clone the repository and open `ColleagueConnect.xcodeproj` in Xcode.
2. Create a GitHub OAuth App under GitHub → Settings → Developer settings → OAuth Apps.
3. Set the Authorization callback URL to `colleagueconnect://auth`.
4. Copy `ColleagueConnect/Secrets.example.xcconfig` to `ColleagueConnect/Secrets.xcconfig`.
5. Open `Secrets.xcconfig` and enter your GitHub OAuth App credentials:

   ```xcconfig
   GITHUB_CLIENT_ID = your_client_id
   GITHUB_CLIENT_SECRET = your_client_secret
   ```

6. The `colleagueconnect` custom URL scheme is already registered in `Info.plist`.
7. Open the project in Xcode, select an iPhone simulator and build the application.

The local `Secrets.xcconfig` file is excluded from version control using `.gitignore`. Never commit real credentials or access tokens.

## OAuth Configuration

GitHub OAuth uses the `colleagueconnect://auth` callback URL.

The authentication service handles authorization URL generation, callback validation, authorization code exchange, token storage, session checks and sign-out.

Access tokens are stored in the iOS Keychain through KeychainSwift.

The OAuth service layer has been implemented. Integration with the WKWebView login screen and application navigation is handled separately.

### Security Considerations

The case study uses a local `.xcconfig` file to supply OAuth credentials.

However, client secrets included in an iOS application can potentially be extracted from the compiled application. An `.xcconfig` file prevents accidental source-control exposure but does not make embedded secrets secure at runtime.

In a production application, a secure backend would typically handle confidential token exchange operations. This project follows the case study requirements without implementing a separate backend.

## Architecture

The project follows VIPER principles to separate responsibilities:

- **View:** Displays information and forwards user interactions.
- **Interactor:** Handles business logic and communicates with services.
- **Presenter:** Prepares data for presentation.
- **Entity:** Represents application data.
- **Router:** Builds modules and manages navigation.

Networking uses URLSession, async/await, endpoint abstractions and Codable models. Protocol-based dependencies support unit testing and separation of concerns.

## Testing

The project includes XCTest coverage for token storage and authentication service behaviour, using mocked dependencies where appropriate.

## Development Notes

The project is being developed incrementally through focused pull requests. OAuth configuration, Keychain token storage and the authentication service are separated into reviewable changes.
