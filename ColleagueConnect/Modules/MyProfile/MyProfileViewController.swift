
import UIKit
import Kingfisher

@MainActor
final class MyProfileViewController: UIViewController {

    var onOpenGitHubProfile: (() -> Void)?
    var onLogoutRequested: (() -> Void)?

    private let profile: HomeViewModel
    private let appBackgroundView = AppBackgroundView()

    init(profile: HomeViewModel) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My Profile"
        view.backgroundColor = AppTheme.Colors.background

        setupUI()
    }

    private func setupUI() {
        let avatarImageView = UIImageView()
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 46
        avatarImageView.backgroundColor = .systemGray6
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.kf.setImage(with: profile.avatarURL)

        NSLayoutConstraint.activate([
        
        
            avatarImageView.widthAnchor.constraint(equalToConstant: 92),
            avatarImageView.heightAnchor.constraint(equalToConstant: 92)
        ])

        let nameLabel = UILabel()
        nameLabel.text = profile.name
        nameLabel.font = .systemFont(ofSize: 23, weight: .bold)
        nameLabel.textColor = AppTheme.Colors.primaryText
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2

        let usernameLabel = UILabel()
        usernameLabel.text = profile.username
        usernameLabel.font = .systemFont(ofSize: 15)
        usernameLabel.textColor = AppTheme.Colors.accent
        usernameLabel.textAlignment = .center

        let profileStack = UIStackView(arrangedSubviews: [
            avatarImageView,
            nameLabel,
            usernameLabel
        ])
        profileStack.axis = .vertical
        profileStack.alignment = .center
        profileStack.spacing = 12
        profileStack.translatesAutoresizingMaskIntoConstraints = false

        let profileCard = makeCard()
        profileCard.addSubview(profileStack)

        NSLayoutConstraint.activate([
            profileStack.topAnchor.constraint(
                equalTo: profileCard.topAnchor,
                constant: 28
            ),
            profileStack.bottomAnchor.constraint(
                equalTo: profileCard.bottomAnchor,
                constant: -28
            ),
            profileStack.leadingAnchor.constraint(
                equalTo: profileCard.leadingAnchor,
                constant: 16
            ),
            profileStack.trailingAnchor.constraint(
                equalTo: profileCard.trailingAnchor,
                constant: -16
            )
        ])

        let githubButton = UIButton(type: .system)
        githubButton.setTitle("View on GitHub ↗", for: .normal)
        githubButton.setTitleColor(.white, for: .normal)
        githubButton.titleLabel?.font = .systemFont(
            ofSize: 16,
            weight: .semibold
        )
        githubButton.backgroundColor = AppTheme.Colors.accent
        githubButton.layer.cornerRadius = 14
        githubButton.heightAnchor.constraint(
            equalToConstant: 54
        ).isActive = true
        githubButton.addTarget(
            self,
            action: #selector(openGitHubTapped),
            for: .touchUpInside
        )

        let logoutButton = makeActionButton(
            title: "Log Out",
            symbol: "rectangle.portrait.and.arrow.right",
            color: .systemRed
        )
        logoutButton.addTarget(
            self,
            action: #selector(logoutTapped),
            for: .touchUpInside
        )

        let separator = UIView()
        separator.backgroundColor = UIColor.systemGray5
        separator.heightAnchor.constraint(
            equalToConstant: 1 / UIScreen.main.scale
        ).isActive = true

        let actionsStack = UIStackView(arrangedSubviews: [
            logoutButton
        ])
        actionsStack.axis = .vertical
        actionsStack.spacing = 0
        actionsStack.translatesAutoresizingMaskIntoConstraints = false

        let actionsCard = makeCard()
        actionsCard.addSubview(actionsStack)

        NSLayoutConstraint.activate([
            actionsStack.topAnchor.constraint(equalTo: actionsCard.topAnchor),
            actionsStack.bottomAnchor.constraint(equalTo: actionsCard.bottomAnchor),
            actionsStack.leadingAnchor.constraint(equalTo: actionsCard.leadingAnchor),
            actionsStack.trailingAnchor.constraint(equalTo: actionsCard.trailingAnchor)
        ])

        let contentStack = UIStackView(arrangedSubviews: [
            profileCard,
            githubButton,
            actionsCard
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear

        appBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appBackgroundView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            appBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            appBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            appBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            appBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentStack.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: 28
            ),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -24
            ),
            contentStack.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                constant: 22
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                constant: -22
            ),
            contentStack.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -44
            )
        ])
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.systemGray5.cgColor
        return card
    }

    private func makeActionButton(
        title: String,
        symbol: String,
        color: UIColor
    ) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePadding = 14
        configuration.baseForegroundColor = color
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 20,
            leading: 18,
            bottom: 20,
            trailing: 18
        )

        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        return button
    }

    @objc private func openGitHubTapped() {
        onOpenGitHubProfile?()
    }

    @objc private func logoutTapped() {
        onLogoutRequested?()
    }
}
