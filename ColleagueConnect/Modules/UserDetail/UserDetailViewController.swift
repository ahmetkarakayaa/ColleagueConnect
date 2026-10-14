
import UIKit
import Kingfisher

@MainActor
final class UserDetailViewController: UIViewController, UserDetailViewInput {

    var presenter: UserDetailViewOutput?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let bioLabel = UILabel()

    private let followersValueLabel = UILabel()
    private let followingValueLabel = UILabel()
    private let joinedLabel = UILabel()

    private let favoriteButton = UIButton(type: .system)
    private let githubButton = UIButton(type: .system)

    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Profile"
        view.backgroundColor = AppTheme.Colors.background

        setupUI()
        presenter?.viewDidLoad()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 18

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 28),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 52
        avatarImageView.backgroundColor = AppTheme.Colors.surface

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 104),
            avatarImageView.heightAnchor.constraint(equalToConstant: 104)
        ])

        nameLabel.font = .systemFont(ofSize: 25, weight: .bold)
        nameLabel.textColor = AppTheme.Colors.primaryText
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0

        usernameLabel.font = .systemFont(ofSize: 15, weight: .medium)
        usernameLabel.textColor = AppTheme.Colors.accent
        usernameLabel.textAlignment = .center

        bioLabel.font = .systemFont(ofSize: 15)
        bioLabel.textColor = AppTheme.Colors.secondaryText
        bioLabel.textAlignment = .center
        bioLabel.numberOfLines = 0

        let avatarContainer = UIView()
        avatarContainer.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor)
        ])

        contentStack.addArrangedSubview(avatarContainer)
        contentStack.addArrangedSubview(nameLabel)
        contentStack.addArrangedSubview(usernameLabel)
        contentStack.addArrangedSubview(bioLabel)

        let statsStack = UIStackView()
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually

        statsStack.addArrangedSubview(
            makeStatCard(valueLabel: followersValueLabel, title: "Followers")
        )
        statsStack.addArrangedSubview(
            makeStatCard(valueLabel: followingValueLabel, title: "Following")
        )

        contentStack.addArrangedSubview(statsStack)

        joinedLabel.font = .systemFont(ofSize: 13)
        joinedLabel.textColor = AppTheme.Colors.secondaryText
        joinedLabel.textAlignment = .center
        contentStack.addArrangedSubview(joinedLabel)

        favoriteButton.tintColor = AppTheme.Colors.accent
        favoriteButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        favoriteButton.layer.cornerRadius = 14
        favoriteButton.layer.borderWidth = 1
        favoriteButton.layer.borderColor = AppTheme.Colors.accent.cgColor
        favoriteButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        favoriteButton.addTarget(
            self,
            action: #selector(favoriteTapped),
            for: .touchUpInside
        )

        githubButton.setTitle("View on GitHub ↗", for: .normal)
        githubButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        githubButton.setTitleColor(.white, for: .normal)
        githubButton.backgroundColor = AppTheme.Colors.accent
        githubButton.layer.cornerRadius = 14
        githubButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        githubButton.addTarget(
            self,
            action: #selector(githubTapped),
            for: .touchUpInside
        )

        contentStack.addArrangedSubview(favoriteButton)
        contentStack.addArrangedSubview(githubButton)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = .systemFont(ofSize: 15)
        errorLabel.textColor = AppTheme.Colors.secondaryText
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        scrollView.isHidden = true
    }

    private func makeStatCard(valueLabel: UILabel, title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = AppTheme.Colors.surface
        container.layer.cornerRadius = 18

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = AppTheme.Colors.secondaryText
        titleLabel.textAlignment = .center

        valueLabel.font = .systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor = AppTheme.Colors.primaryText
        valueLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        ])

        return container
    }

    func displayLoading() {
        scrollView.isHidden = true
        errorLabel.isHidden = true
        activityIndicator.startAnimating()
    }

    func displayUser(_ user: UserDetailEntity, isFavorite: Bool) {
        activityIndicator.stopAnimating()
        errorLabel.isHidden = true
        scrollView.isHidden = false

        nameLabel.text = user.name?.isEmpty == false ? user.name : user.login
        usernameLabel.text = "@\(user.login)"
        bioLabel.text = user.bio?.isEmpty == false ? user.bio : "No bio available."

        followersValueLabel.text = user.followers.formatted()
        followingValueLabel.text = user.following.formatted()

        avatarImageView.kf.setImage(with: user.avatarURL)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")

        joinedLabel.text = "Joined \(formatter.string(from: user.createdAt))"

        let heartName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: heartName), for: .normal)
        favoriteButton.setTitle(
            isFavorite ? "  Remove from Favorites" : "  Add to Favorites",
            for: .normal
        )
    }

    func displayError(_ message: String) {
        activityIndicator.stopAnimating()
        scrollView.isHidden = true
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    @objc private func favoriteTapped() {
        presenter?.didTapFavorite()
    }

    @objc private func githubTapped() {
        presenter?.didTapGitHub()
    }
}
