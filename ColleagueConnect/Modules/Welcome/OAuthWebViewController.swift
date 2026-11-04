
import UIKit
import WebKit

@MainActor
final class OAuthWebViewController: UIViewController {

    private let authorizationURL: URL
    private let callbackScheme: String
    private let onCallback: (URL) -> Void
    private let onCancel: () -> Void
    private let onError: (Error) -> Void

    private var hasFinished = false

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    init(
        authorizationURL: URL,
        callbackScheme: String,
        onCallback: @escaping (URL) -> Void,
        onCancel: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.authorizationURL = authorizationURL
        self.callbackScheme = callbackScheme
        self.onCallback = onCallback
        self.onCancel = onCancel
        self.onError = onError

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        webView.load(URLRequest(url: authorizationURL))
    }

    private func setupUI() {
        title = "Sign in with GitHub"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )

        view.addSubview(webView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            webView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            webView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            webView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
            activityIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            )
        ])
    }

    @objc
    private func cancelTapped() {
        guard !hasFinished else { return }

        hasFinished = true
        webView.stopLoading()
        onCancel()
    }

    private func finishWithError(_ error: Error) {
        guard !hasFinished else { return }

        hasFinished = true
        activityIndicator.stopAnimating()
        webView.stopLoading()
        onError(error)
    }
}

extension OAuthWebViewController: WKNavigationDelegate {

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.scheme?.lowercased() == callbackScheme.lowercased() {
            decisionHandler(.cancel)

            guard !hasFinished else { return }

            hasFinished = true
            activityIndicator.stopAnimating()
            onCallback(url)
            return
        }

        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        activityIndicator.startAnimating()
    }

    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        activityIndicator.stopAnimating()
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        guard (error as? URLError)?.code != .cancelled else {
            return
        }

        finishWithError(error)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        guard (error as? URLError)?.code != .cancelled else {
            return
        }

        finishWithError(error)
    }
}
