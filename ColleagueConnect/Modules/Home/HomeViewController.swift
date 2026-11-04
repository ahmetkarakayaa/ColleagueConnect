
import UIKit
import Kingfisher

@MainActor
final class HomeViewController: UIViewController, HomeViewInput {

    var presenter: HomeViewOutput?

    private enum Layout {
        static let horizontalInset: CGFloat = 22
        static let avatarSize: CGFloat = 76
        static let cornerRadius: CGFloat = 18
        static let spacing: CGFloat = 22
    }

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let bioLabel = UILabel()
    private let followersLabel = UILabel()
    private let followingLabel = UILabel()
    private let favoritesLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorStack = UIStackView()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let recentFavoritesView = HomeRecentFavoritesView()

    var onSeeAllFavorites: (() -> Void)? {
        didSet {
            recentFavoritesView.onSeeAllTapped = onSeeAllFavorites
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.Colors.background

        setupContent()
        setupLoadingAndError()

        presenter?.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(
            true,
            animated: false
        )

        presenter?.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(
            false,
            animated: false
        )
    }


    private func setupContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isHidden = true
        scrollView.alwaysBounceVertical = true

        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = Layout.spacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentStack)

        let header = makeHeader()
        let profileCard = makeProfileCard()
        let statsStack = makeStatsStack()

        contentStack.addArrangedSubview(header)
        contentStack.addArrangedSubview(profileCard)
        contentStack.addArrangedSubview(statsStack)
        contentStack.addArrangedSubview(recentFavoritesView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: 24
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
                constant: -32
            ),
            contentStack.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -Layout.horizontalInset * 2
            )
        ])
    }

    private func makeHeader() -> UIView {
        let logoImageView = UIImageView(
            image: UIImage(systemName: "person.2.fill")
        )
        logoImageView.tintColor = AppTheme.Colors.accent
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        let brandText = NSMutableAttributedString(
            string: "Colleague",
            attributes: [
                .font: UIFont.systemFont(ofSize: 19, weight: .bold),
                .foregroundColor: AppTheme.Colors.primaryText
            ]
        )

        brandText.append(
            NSAttributedString(
                string: "Connect",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 19, weight: .bold),
                    .foregroundColor: AppTheme.Colors.accent
                ]
            )
        )

        let brandLabel = UILabel()
        brandLabel.attributedText = brandText

        let brandStack = UIStackView(arrangedSubviews: [
            logoImageView,
            brandLabel
        ])
        brandStack.axis = .horizontal
        brandStack.alignment = .center
        brandStack.spacing = 10

        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 26),
            logoImageView.heightAnchor.constraint(equalToConstant: 26)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Home"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = AppTheme.Colors.primaryText

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Your profile and favorites at a glance."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = AppTheme.Colors.secondaryText
        subtitleLabel.numberOfLines = 0

        let titleStack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel
        ])
        titleStack.axis = .vertical
        titleStack.spacing = 4

        let headerStack = UIStackView(arrangedSubviews: [
            brandStack,
            titleStack
        ])
        headerStack.axis = .vertical
        headerStack.spacing = 24

        return headerStack
    }

    private func makeProfileCard() -> UIView {
        let card = UIView()
        card.backgroundColor = AppTheme.Colors.surface
        card.layer.cornerRadius = Layout.cornerRadius
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.separator.withAlphaComponent(0.25).cgColor

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = Layout.avatarSize / 2
        avatarImageView.backgroundColor = AppTheme.Colors.background
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.textColor = AppTheme.Colors.primaryText
        nameLabel.numberOfLines = 2

        usernameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        usernameLabel.textColor = AppTheme.Colors.accent
        usernameLabel.lineBreakMode = .byTruncatingMiddle

        bioLabel.font = .systemFont(ofSize: 13)
        bioLabel.textColor = AppTheme.Colors.secondaryText
        bioLabel.numberOfLines = 3

        let detailsStack = UIStackView(arrangedSubviews: [
            nameLabel,
            usernameLabel,
            bioLabel
        ])
        detailsStack.axis = .vertical
        detailsStack.alignment = .fill
        detailsStack.spacing = 6

        let profileStack = UIStackView(arrangedSubviews: [
            avatarImageView,
            detailsStack
        ])
        profileStack.axis = .horizontal
        profileStack.alignment = .center
        profileStack.spacing = 14
        profileStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(profileStack)

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(
                equalToConstant: Layout.avatarSize
            ),
            avatarImageView.heightAnchor.constraint(
                equalToConstant: Layout.avatarSize
            ),
            profileStack.topAnchor.constraint(
                equalTo: card.topAnchor,
                constant: 20
            ),
            profileStack.bottomAnchor.constraint(
                equalTo: card.bottomAnchor,
                constant: -20
            ),
            profileStack.leadingAnchor.constraint(
                equalTo: card.leadingAnchor,
                constant: 16
            ),
            profileStack.trailingAnchor.constraint(
                equalTo: card.trailingAnchor,
                constant: -16
            )
        ])

        return card
    }


    private func makeStatsStack() -> UIView {
        let followersCard = makeStatCard(
            title: "Followers",
            valueLabel: followersLabel
        )

        let followingCard = makeStatCard(
            title: "Following",
            valueLabel: followingLabel
        )

        let favoritesCard = makeStatCard(
            title: "Favorites",
            valueLabel: favoritesLabel
        )

        let stack = UIStackView(arrangedSubviews: [
            followersCard,
            followingCard,
            favoritesCard
        ])

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10

        return stack
    }


    private func makeStatCard(
        title: String,
        valueLabel: UILabel
    ) -> UIView {
        let card = UIView()
        card.backgroundColor = AppTheme.Colors.surface
        card.layer.cornerRadius = 16

        valueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        valueLabel.textColor = AppTheme.Colors.primaryText
        valueLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = AppTheme.Colors.secondaryText
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [
            valueLabel,
            titleLabel
        ])

        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(
                equalTo: card.topAnchor,
                constant: 20
            ),
            stack.bottomAnchor.constraint(
                equalTo: card.bottomAnchor,
                constant: -20
            ),
            stack.leadingAnchor.constraint(
                equalTo: card.leadingAnchor,
                constant: 8
            ),
            stack.trailingAnchor.constraint(
                equalTo: card.trailingAnchor,
                constant: -8
            )
        ])

        return card
    }

    private func setupLoadingAndError() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        errorLabel.font = .systemFont(ofSize: 15)
        errorLabel.textColor = AppTheme.Colors.secondaryText
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0

        retryButton.setTitle("Try Again", for: .normal)
        retryButton.tintColor = AppTheme.Colors.accent
        retryButton.titleLabel?.font = .systemFont(
            ofSize: 15,
            weight: .semibold
        )
        retryButton.addTarget(
            self,
            action: #selector(retryTapped),
            for: .touchUpInside
        )

        errorStack.axis = .vertical
        errorStack.alignment = .center
        errorStack.spacing = 12
        errorStack.isHidden = true
        errorStack.translatesAutoresizingMaskIntoConstraints = false
        errorStack.addArrangedSubview(errorLabel)
        errorStack.addArrangedSubview(retryButton)

        view.addSubview(errorStack)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            errorStack.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            errorStack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 32
            ),
            errorStack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -32
            )
        ])
    }

    func displayLoading() {
        scrollView.isHidden = true
        errorStack.isHidden = true
        activityIndicator.startAnimating()
    }

    func displayProfile(_ model: HomeViewModel) {
        activityIndicator.stopAnimating()
        errorStack.isHidden = true
        scrollView.isHidden = false

        nameLabel.text = model.name
        usernameLabel.text = model.username
        bioLabel.text = model.bio
        bioLabel.isHidden = model.bio?.isEmpty != false

        followersLabel.text = model.followers
        followingLabel.text = model.following

        avatarImageView.kf.setImage(with: model.avatarURL)
    }

    func displayError(_ message: String) {
        activityIndicator.stopAnimating()
        scrollView.isHidden = true
        errorLabel.text = message
        errorStack.isHidden = false
    }
    func displayFavorites(_ model: HomeFavoritesViewModel) {
        favoritesLabel.text = model.totalCount

        recentFavoritesView.configure(
            users: model.recentUsers
        )
    }
    @objc private func retryTapped() {
        presenter?.didTapRetry()
    }
}
