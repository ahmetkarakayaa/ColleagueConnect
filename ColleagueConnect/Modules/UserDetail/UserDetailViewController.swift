import UIKit
import Kingfisher

@MainActor
final class UserDetailViewController: UIViewController, UserDetailViewInput {

    var presenter: UserDetailViewOutput?


    private enum Layout {
        static let contentSpacing: CGFloat = 18
        static let horizontalInset: CGFloat = 24
        static let topInset: CGFloat = 28
        static let bottomInset: CGFloat = 32
        static let avatarSize: CGFloat = 104
        static let buttonHeight: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 14
        static let statCardCornerRadius: CGFloat = 18
        static let statSpacing: CGFloat = 12
    }


    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isHidden = true
        return scrollView
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = Layout.contentSpacing
        return stack
    }()


    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.avatarSize / 2
        imageView.backgroundColor = AppTheme.Colors.surface

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            imageView.heightAnchor.constraint(equalToConstant: Layout.avatarSize)
        ])

        return imageView
    }()

    private lazy var avatarContainer: UIView = {
        let container = UIView()
        container.addSubview(avatarImageView)

        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: container.topAnchor),
            avatarImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 25, weight: .bold)
        label.textColor = AppTheme.Colors.primaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = AppTheme.Colors.accent
        label.textAlignment = .center
        return label
    }()

    private lazy var bioLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = AppTheme.Colors.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()


    private lazy var followersValueLabel = makeStatValueLabel()
    private lazy var followingValueLabel = makeStatValueLabel()

    private lazy var statsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            makeStatCard(valueLabel: followersValueLabel, title: "Followers"),
            makeStatCard(valueLabel: followingValueLabel, title: "Following")
        ])
        stack.axis = .horizontal
        stack.spacing = Layout.statSpacing
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var joinedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = AppTheme.Colors.secondaryText
        label.textAlignment = .center
        return label
    }()

    private lazy var joinedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()


    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppTheme.Colors.accent
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.layer.borderWidth = 1
        button.layer.borderColor = AppTheme.Colors.accent.cgColor
        button.heightAnchor.constraint(equalToConstant: Layout.buttonHeight).isActive = true
        button.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        return button
    }()

    private lazy var githubButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View on GitHub ↗", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = AppTheme.Colors.accent
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.heightAnchor.constraint(equalToConstant: Layout.buttonHeight).isActive = true
        button.addTarget(self, action: #selector(githubTapped), for: .touchUpInside)
        return button
    }()


    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15)
        label.textColor = AppTheme.Colors.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Profile"
        view.backgroundColor = AppTheme.Colors.background

        setupHierarchy()
        setupConstraints()

        presenter?.viewDidLoad()
    }


    private func setupHierarchy() {
        view.addSubview(scrollView)
        view.addSubview(activityIndicator)
        view.addSubview(errorLabel)

        scrollView.addSubview(contentStack)

        [
            avatarContainer,
            nameLabel,
            usernameLabel,
            bioLabel,
            statsStack,
            joinedLabel,
            favoriteButton,
            githubButton
        ].forEach(contentStack.addArrangedSubview)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: Layout.topInset
            ),
            contentStack.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                constant: Layout.horizontalInset
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                constant: -Layout.horizontalInset
            ),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -Layout.bottomInset
            ),
            contentStack.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -Layout.horizontalInset * 2
            ),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Layout.horizontalInset
            ),
            errorLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Layout.horizontalInset
            )
        ])
    }


    private func makeStatValueLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = AppTheme.Colors.primaryText
        label.textAlignment = .center
        return label
    }

    private func makeStatCard(valueLabel: UILabel, title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = AppTheme.Colors.surface
        container.layer.cornerRadius = Layout.statCardCornerRadius

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = AppTheme.Colors.secondaryText
        titleLabel.textAlignment = .center

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

        nameLabel.text = user.name.nonEmpty ?? user.login
        usernameLabel.text = "@\(user.login)"
        bioLabel.text = user.bio.nonEmpty ?? "No bio available."

        followersValueLabel.text = user.followers.formatted()
        followingValueLabel.text = user.following.formatted()

        avatarImageView.kf.setImage(with: user.avatarURL)

        joinedLabel.text = "Joined \(joinedDateFormatter.string(from: user.createdAt))"

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


private extension Optional where Wrapped == String {

    /// Returns the string only if it is non-nil and not empty.
    var nonEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}
