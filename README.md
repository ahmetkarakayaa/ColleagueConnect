# ColleagueConnect

**iOS Internship Case Study | n11**

ColleagueConnect is a native iOS application developed as part of an iOS development internship case study at n11.

Built with **Swift, UIKit, and VIPER architecture**, the application integrates with the GitHub REST API to provide user discovery, profile management, favorites, follow interactions, and recently viewed profiles.

## Features

### Authentication
- GitHub OAuth authentication
- Secure access token storage using Keychain
- Session management and logout

### Home Dashboard
- Authenticated GitHub user profile
- Followers, following, and favorites statistics
- Recent Favorites and Recently Viewed sections
- Navigation to user profiles and related lists

### User Search
- GitHub user search with debouncing
- Profile cards displaying avatars, names, and biographies
- Sorting and filtering options
- Favorite management
- Loading, empty, and error states

### User Profiles
- Detailed GitHub profile information
- Followers and following statistics
- Add or remove favorites
- Follow and unfollow GitHub users
- View profiles directly on GitHub

### Follow Management
- Followers and Following lists
- Follow status checking and caching
- Optimistic UI updates for Follow/Unfollow actions
- HTTP response validation and error handling
- Synchronization of following statistics across screens

### Favorites
- Persistent favorite user management
- Search and sorting
- Cached profile information
- Concurrent profile loading
- Partial success handling when individual requests fail

### Recently Viewed
- Local browsing history using UserDefaults
- Most recently viewed profiles displayed first
- Prevention of duplicate history entries
- Individual history deletion using swipe actions
- Clear All functionality

### Connectivity and Error Handling
- Internet connectivity monitoring using NWPathMonitor
- Dedicated offline state
- Retry mechanisms
- GitHub API error and rate-limit handling
- Swift Concurrency task cancellation

## Tech Stack

- **Language:** Swift
- **UI:** UIKit, Programmatic Auto Layout
- **Architecture:** VIPER
- **Networking:** URLSession, GitHub REST API
- **Authentication:** GitHub OAuth
- **Secure Storage:** Keychain
- **Local Storage:** UserDefaults
- **Concurrency:** async/await, Task, TaskGroup
- **Image Loading:** Kingfisher
- **Testing:** XCTest, XCUITest
- **Version Control:** Git, GitHub

## Architecture

ColleagueConnect uses VIPER architecture to separate application responsibilities:

- **View:** Displays information and handles user interactions.
- **Interactor:** Manages business logic and data operations.
- **Presenter:** Coordinates presentation logic and prepares ViewModels.
- **Entity:** Represents domain data.
- **Router:** Handles navigation and module assembly.

The project also uses protocol-oriented programming, dependency injection, DTO-to-Entity mapping, and reusable service components.

Some supporting screens use a simplified structure while sharing the application's existing service and navigation infrastructure.

## Testing

The project includes automated unit and UI tests implemented with XCTest and XCUITest.

**Latest verified test run: 21 passed, 0 failed.**

Test coverage includes:

- Favorite storage, ordering, and removal
- Duplicate favorite prevention
- Profile caching and network request optimization
- Partial failure handling
- Missing authentication tokens
- Authenticated user requests
- Home Presenter loading and error states
- Retry functionality
- Application launch and UI launch configurations

## Development Workflow

Development was carried out using Git and GitHub with feature branches, Pull Requests, and Code Reviews.

Code reviews focused on architecture responsibilities, dependency injection, asynchronous operations, error handling, caching strategies, and maintainability.

## Getting Started

1. Clone the repository.
2. Open `ColleagueConnect.xcodeproj` in Xcode.
3. Configure the required GitHub OAuth credentials and callback settings.
4. Select an iOS Simulator.
5. Build and run the application.

GitHub OAuth configuration is required for authenticated features. Credentials and secrets should not be committed to the repository.

## Project Context

Developed as an **iOS internship case study at n11**, focusing on native iOS development, REST API integration, software architecture, asynchronous programming, testing, and collaborative development workflows.
