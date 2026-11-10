import UIKit
import Kingfisher

@MainActor
final class HomeViewController: UIViewController, HomeViewInput {


    var presenter: HomeViewOutput?


    var onProfileTapped: ((HomeViewModel) -> Void)?
    var onSeeAllFavorites: (() -> Void)?
    var onRecentFavoriteTapped: ((String) -> Void)?
    var onSeeAllViewed: (() -> Void)?
    var onViewedProfileTapped: ((String) -> Void)?
    var onOpenGitHubProfile: ((String) -> Void)?
    var onLogoutRequested: (() -> Void)?


    private enum Layout {
        static let horizontalInset: CGFloat = 22
        static let contentTop: CGFloat = 24
        static let contentBottom: CGFloat = 32
        static let spacing: CGFloat = 22
        static let cardCornerRadius: CGFloat = 18
        static let avatarSize: CGFloat = 76
        static let errorInset: CGFloat = 32
    }


    private let appBackgroundView = AppBackgroundView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let bioLabel = UILabel()

    private let followersCard = StatCardView(title: "Followers")
    private let followingCard = StatCardView(title: "Following")
    private let favoritesCard = StatCardView(title: "Favorites")

    private let recentFavoritesView = HomeRecentFavoritesView()
    private let recentlyViewedView = HomeRecentlyViewedView()

    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorStack = UIStackView()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)


    private var displayedProfile: HomeViewModel?


    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.Colors.background

        setupBackground()
        setupContent()
        setupLoadingAndError()
        bindCallbacks()

        presenter?.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        presenter?.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func setupBackground() {
        appBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(appBackgroundView, at: 0)
        appBackgroundView.pinEdges(to: view)
    }

    
    private func bindCallbacks() {
        recentFavoritesView.onSeeAllTapped = { [weak self] in
            self?.onSeeAllFavorites?()
        }
        recentFavoritesView.onFavoriteTapped = { [weak self] username in
            self?.onRecentFavoriteTapped?(username)
        }
        recentlyViewedView.onSeeAllTapped = { [weak self] in
            self?.onSeeAllViewed?()
        }
        recentlyViewedView.onProfileTapped = { [weak self] username in
            self?.onViewedProfileTapped?(username)
        }
    }

    private func setupContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isHidden = true
        // İçerik ekrana sığıyorsa bounce yok, sığmıyorsa kayar.
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false

        contentStack.axis = .vertical
        contentStack.spacing = Layout.spacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.addArrangedSubviews([
            makeHeader(),
            makeProfileCard(),
            makeStatsStack(),
            recentFavoritesView,
            recentlyViewedView
        ])

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: Layout.contentTop
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
                constant: -Layout.contentBottom
            ),
            contentStack.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor,
                constant: -Layout.horizontalInset * 2
            )
        ])
    }

    private func setupLoadingAndError() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        errorLabel.font = .systemFont(ofSize: 15)
        errorLabel.textColor = AppTheme.Colors.secondaryText
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0

        retryButton.setTitle("Try Again", for: .normal)
        retryButton.tintColor = AppTheme.Colors.accent
        retryButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        errorStack.axis = .vertical
        errorStack.alignment = .center
        errorStack.spacing = 12
        errorStack.isHidden = true
        errorStack.translatesAutoresizingMaskIntoConstraints = false
        errorStack.addArrangedSubviews([errorLabel, retryButton])

        view.addSubview(activityIndicator)
        view.addSubview(errorStack)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorStack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Layout.errorInset
            ),
            errorStack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Layout.errorInset
            )
        ])
    }


    private func makeHeader() -> UIView {
        let logoImageView = UIImageView(image: UIImage(systemName: "person.2.fill"))
        logoImageView.tintColor = AppTheme.Colors.accent
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        let brandFont = UIFont.systemFont(ofSize: 19, weight: .bold)
        let brandText = NSMutableAttributedString(
            string: "Colleague",
            attributes: [
                .font: brandFont,
                .foregroundColor: AppTheme.Colors.primaryText
            ]
        )
        brandText.append(NSAttributedString(
            string: "Connect",
            attributes: [
                .font: brandFont,
                .foregroundColor: AppTheme.Colors.accent
            ]
        ))

        let brandLabel = UILabel()
        brandLabel.attributedText = brandText

        let brandStack = UIStackView(arrangedSubviews: [logoImageView, brandLabel])
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

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 4

        let headerStack = UIStackView(arrangedSubviews: [brandStack, titleStack])
        headerStack.axis = .vertical
        headerStack.spacing = 24

        return headerStack
    }

    private func makeProfileCard() -> UIView {
        let card = UIView()
        card.applyCardStyle(cornerRadius: Layout.cardCornerRadius)

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

        let detailsStack = UIStackView(arrangedSubviews: [nameLabel, usernameLabel, bioLabel])
        detailsStack.axis = .vertical
        detailsStack.alignment = .fill
        detailsStack.spacing = 6
        detailsStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false

        let profileStack = UIStackView(arrangedSubviews: [
            avatarImageView,
            detailsStack,
            chevronImageView
        ])
        profileStack.axis = .horizontal
        profileStack.alignment = .center
        profileStack.spacing = 14
        profileStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(profileStack)
        profileStack.pinEdges(
            to: card,
            insets: UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        )

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: Layout.avatarSize),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 18)
        ])

        card.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(profileCardTapped))
        )
        card.isAccessibilityElement = true
        card.accessibilityTraits = .button
        card.accessibilityLabel = "Profile actions"

        return card
    }

    private func makeStatsStack() -> UIView {
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


    func displayLoading() {
        errorStack.isHidden = true
        scrollView.isHidden = displayedProfile == nil
        activityIndicator.startAnimating()
    }

    func displayProfile(_ model: HomeViewModel) {
        displayedProfile = model

        activityIndicator.stopAnimating()
        errorStack.isHidden = true
        scrollView.isHidden = false

        nameLabel.text = model.name
        usernameLabel.text = model.username
        bioLabel.text = model.bio
        bioLabel.isHidden = model.bio?.isEmpty ?? true

        followersCard.setValue(model.followers)
        followingCard.setValue(model.following)

        avatarImageView.kf.setImage(
            with: model.avatarURL,
            options: [.transition(.fade(0.2))]
        )
    }

    func displayError(_ message: String) {
        activityIndicator.stopAnimating()
        scrollView.isHidden = true
        errorLabel.text = message
        errorStack.isHidden = false
    }

    func displayFavorites(_ model: HomeFavoritesViewModel) {
        favoritesCard.setValue(model.totalCount)
        recentFavoritesView.configure(users: model.recentUsers)
    }

    func displayRecentlyViewed(_ users: [HomeRecentFavoriteViewModel]) {
        recentlyViewedView.configure(users: users)
    }


    @objc private func retryTapped() {
        presenter?.didTapRetry()
    }

    @objc private func profileCardTapped() {
        guard let displayedProfile else { return }
        onProfileTapped?(displayedProfile)
    }
}


private final class StatCardView: UIView {

    private let valueLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)

        applyCardStyle(cornerRadius: 16)

        valueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        valueLabel.textColor = AppTheme.Colors.primaryText
        valueLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = AppTheme.Colors.secondaryText
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        stack.pinEdges(
            to: self,
            insets: UIEdgeInsets(top: 20, left: 8, bottom: 20, right: 8)
        )

        isAccessibilityElement = true
        accessibilityLabel = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ text: String?) {
        valueLabel.text = text
        accessibilityValue = text
    }
}


private extension UIView {

    func applyCardStyle(cornerRadius: CGFloat) {
        backgroundColor = .white
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor
    }

    func pinEdges(to other: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom)
        ])
    }
}

private extension UIStackView {

    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach(addArrangedSubview)
    }
}
