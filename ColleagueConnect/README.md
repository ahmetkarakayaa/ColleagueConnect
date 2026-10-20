# ColleagueConnect

ColleagueConnect is an iOS application built with UIKit and VIPER architecture. It provides GitHub user search, profile details, and favorites management.

## Technologies

- Swift
- UIKit
- VIPER
- Async/Await
- GitHub REST API

## Project Setup

1. Clone the repository and open `ColleagueConnect.xcodeproj` in Xcode.
2. Register a GitHub OAuth App under GitHub > Settings > Developer settings > OAuth Apps.
3. Set the Authorization callback URL to `colleagueconnect://auth`.
4. Copy `ColleagueConnect/Secrets.example.xcconfig` to `ColleagueConnect/Secrets.xcconfig`.
5. Set `GITHUB_CLIENT_ID` in `Secrets.xcconfig` using your GitHub OAuth App Client ID.
6. The `colleagueconnect` URL scheme is already configured in `Info.plist`; no changes are required.
7. Select an iOS simulator and build the project.

OAuth authentication is not yet implemented. Client Secret handling and token exchange will be addressed in the authentication service implementation.

## OAuth Configuration

The application uses the `colleagueconnect` URL scheme for OAuth callbacks.

The local `Secrets.xcconfig` file is excluded from Git using `.gitignore`. Do not commit credentials or client secrets to the repository.

GitHub OAuth authentication is planned as a separate feature and is not yet implemented.

## Architecture

The project follows VIPER principles to separate presentation, business logic, navigation, and data responsibilities.
