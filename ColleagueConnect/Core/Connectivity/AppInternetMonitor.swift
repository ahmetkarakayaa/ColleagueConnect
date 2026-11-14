
import UIKit
import Network

@MainActor
final class AppInternetMonitor {

    static let shared = AppInternetMonitor()
    static let retryNotification = Notification.Name("appInternetRetryRequested")

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "AppInternetMonitorQueue")

    private(set) var isConnected = true
    private var overlayWindow: UIWindow?
    private var isRetrying = false

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }

                let connected = self.monitor.currentPath.status == .satisfied
                self.handleConnectionChange(isConnected: connected)
            }
        }

        monitor.start(queue: monitorQueue)
    }


    private func handleConnectionChange(isConnected connected: Bool) {
        let wasConnected = isConnected
        isConnected = connected

        if !connected {
            showNoInternetOverlay()
            return
        }

        guard wasConnected == false else {
            return
        }

        hideNoInternetOverlay()
        notifyRetry()
    }


    func showOffline() {
        guard monitor.currentPath.status == .unsatisfied else {
            return
        }

        handleConnectionChange(isConnected: false)
    }

    private func showNoInternetOverlay() {
        guard overlayWindow == nil else { return }

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .alert + 1

        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: UIImage(named: "NoInternet"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 220),
            imageView.heightAnchor.constraint(equalToConstant: 220)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "No internet connection"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center

        let descriptionLabel = UILabel()
        descriptionLabel.font = .systemFont(ofSize: 15)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0

        let retryButton = UIButton(type: .system)

        var configuration = UIButton.Configuration.plain()
        configuration.title = "Try Again"
        configuration.image = UIImage(
            systemName: "arrow.clockwise",
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: 13,
                weight: .medium
            )
        )
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 7
        configuration.baseForegroundColor = UIColor(
            red: 0.76,
            green: 0.13,
            blue: 0.68,
            alpha: 1
        )
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 12
        )

        retryButton.configuration = configuration
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(
            self,
            action: #selector(retryTapped),
            for: .touchUpInside
        )

        [
            imageView,
            titleLabel,
            descriptionLabel,
            retryButton
        ].forEach(stack.addArrangedSubview)

        viewController.view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            stack.leadingAnchor.constraint(
                greaterThanOrEqualTo: viewController.view.leadingAnchor,
                constant: 32
            ),
            stack.trailingAnchor.constraint(
                lessThanOrEqualTo: viewController.view.trailingAnchor,
                constant: -32
            )
        ])

        window.rootViewController = viewController
        overlayWindow = window
        window.makeKeyAndVisible()
    }

    private func hideNoInternetOverlay() {
        guard let window = overlayWindow else { return }

        overlayWindow = nil
        window.isHidden = true

        if let mainWindow = window.windowScene?.windows.first(where: {
            $0 !== window && $0.windowLevel == .normal
        }) {
            mainWindow.makeKey()
        }
    }

    private func notifyRetry() {
        NotificationCenter.default.post(
            name: Self.retryNotification,
            object: nil
        )
    }

    @objc private func retryTapped() {
        guard !isRetrying else { return }
        isRetrying = true

        Task {
            defer { isRetrying = false }

            guard let url = URL(string: "https://api.github.com") else {
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 4

            do {
                let (_, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...499).contains(httpResponse.statusCode)
                else {
                    return
                }

                guard overlayWindow != nil else { return }

                hideNoInternetOverlay()
                notifyRetry()
            } catch {
                return
            }
        }
    }
}

