# ColleagueConnect

ColleagueConnect is an iOS application developed as part of the n11 iOS Intern Case Study. It allows users to authenticate with GitHub, search for people, explore user profiles, and manage a personal favourites list.

The application is built with **Swift, UIKit and VIPER architecture**, with a focus on clean code, separation of responsibilities, error handling and testability.

## Features

- **GitHub Authentication:** Sign in with GitHub OAuth 2.0 and maintain a user session.
- **Home Dashboard:** View the authenticated user's profile, statistics, recent favourites and recently viewed profiles.
- **User Search:** Search GitHub users and display results in a two-column grid.
- **User Details:** View profile images, names, biographies, follower counts, following counts and account creation dates.
- **Favourites:** Add or remove users, search saved profiles and sort by date added or username.
- **Local Persistence:** Preserve favourite users between application launches.
- **Error Handling:** Display loading, empty, offline, request failure and API rate-limit states.
- **Session Management:** Securely store access tokens and support logout.

## Technology Stack

| Category | Technology |
|---|---|
| Language | Swift |
| UI | UIKit, Auto Layout |
| Architecture | VIPER |
| Networking | URLSession, async/await |
| Data Source | GitHub REST API |
| Authentication | GitHub OAuth 2.0, WKWebView |
| Token Storage | KeychainSwift |
| Image Loading | Kingfisher |
| Local Storage | UserDefaults |
| Dependencies | Swift Package Manager |
| Testing | XCTest |

## Requirements

- Xcode 15.4
- Swift 5.10
- iOS 16.6 or later
- A GitHub OAuth application

## Installation

1. Clone the repository.
2. Open `ColleagueConnect.xcodeproj` in Xcode.
3. Create a GitHub OAuth App in GitHub Settings → Developer settings → OAuth Apps.
4. Set the authorization callback URL to `colleagueconnect://auth`.
5. Copy `ColleagueConnect/Secrets.example.xcconfig` to `ColleagueConnect/Secrets.xcconfig`.
6. Enter your OAuth credentials in the local configuration file:

```xcconfig
GITHUB_CLIENT_ID = your_client_id
GITHUB_CLIENT_SECRET = your_client_secret
```

7. Select an iPhone simulator or a configured physical device.
8. Build and run the project.

The custom URL scheme is configured in the application.

**Important:** `Secrets.xcconfig` is excluded from Git using `.gitignore`. Never commit real credentials or access tokens.

## Architecture

The project follows the VIPER architectural pattern.

- **View:** Displays information and forwards user interactions.
- **Interactor:** Handles business logic and communicates with networking and storage services.
- **Presenter:** Coordinates presentation logic and transforms data into ViewModels.
- **Entity:** Represents application data independently of presentation concerns.
- **Router:** Creates modules and manages navigation.

The application also uses protocol-based dependency injection to support modularity and unit testing.

### Project Structure

```text
ColleagueConnect/
├── App/
├── Core/
│   ├── Connectivity/
│   ├── DesignSystem/
│   ├── Models/
│   ├── Network/
│   └── Services/
├── Modules/
│   ├── Welcome/
│   ├── Home/
│   ├── Search/
│   ├── UserDetail/
│   ├── Favorites/
│   ├── MyProfile/
│   └── RecentlyViewed/
└── Assets.xcassets/
```

## Key Technical Decisions

**VIPER Architecture:** Separates UI, presentation, business logic and navigation responsibilities to improve maintainability.

**Protocol-Based Dependencies:** Allows services and interactors to be replaced with mock implementations during testing.

**DTO and Entity Separation:** Keeps API response structures separate from application models.

**Async/Await Networking:** Provides readable asynchronous request handling and supports cancellation.

**Search Debouncing:** Reduces unnecessary API requests while users are typing.

**Favourites Persistence:** Uses a dedicated service backed by UserDefaults to preserve saved users.

**Caching and Partial Success:** Reuses previously loaded user profiles and allows available favourites to be displayed when individual profile requests fail.

## Security

Authentication uses GitHub OAuth 2.0. Access tokens are stored using KeychainSwift.

For this case study, OAuth configuration values are supplied using a local `.xcconfig` file.

However, embedding a Client Secret in a mobile application is not fully secure because compiled applications can be inspected. A production application should use an appropriate backend-based authentication architecture to keep confidential credentials outside the mobile client.

## Testing

The project includes XCTest unit tests for application components, including Home presentation and interaction logic and favourite storage behaviour.

Mock dependencies are used to test behaviours independently from real API responses.

Builds and unit tests were completed successfully during development. Main user flows were also manually verified using the iOS simulator.

Automated UI testing was not fully verified because of development environment permission restrictions.

## Future Improvements

With additional development time, the project could be extended with:

- Search result pagination
- More comprehensive automated UI testing
- Dynamic Type and VoiceOver accessibility support
- Complete Dark Mode support
- Turkish and English localization
- Backend-based OAuth token exchange for stronger credential protection

## Development Process

The application was developed through Git branches, pull requests, code reviews and iterative improvements.

The development process focused on maintainable architecture, reliable error handling, testability and consistent user experience.
