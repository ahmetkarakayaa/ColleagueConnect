
import UIKit
import Kingfisher

@MainActor
final class HomeRecentFavoritesView: UIView {

    var onSeeAllTapped: (() -> Void)? {
        didSet {
            seeAllButton.isHidden = onSeeAllTapped == nil
        }
    }

    private let rowsStack = UIStackView()

    private let seeAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("See All", for: .normal)
        button.setTitleColor(AppTheme.Colors.accent, for: .normal)
        button.titleLabel?.font = .systemFont(
            ofSize: 14,
            weight: .semibold
        )
        button.isHidden = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let titleLabel = UILabel()
        titleLabel.text = "Recent Favorites"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = AppTheme.Colors.primaryText

        seeAllButton.addTarget(
            self,
            action: #selector(seeAllTapped),
            for: .touchUpInside
        )

        let headerStack = UIStackView(arrangedSubviews: [
            titleLabel,
            seeAllButton
        ])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing

        let card = UIView()
        card.backgroundColor = AppTheme.Colors.background
        card.layer.cornerRadius = AppTheme.Radius.card
        card.layer.borderWidth = 1
        card.layer.borderColor = AppTheme.Colors.border
            .withAlphaComponent(0.3).cgColor

        rowsStack.axis = .vertical
        rowsStack.spacing = 0
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(rowsStack)

        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(
                equalTo: card.topAnchor,
                constant: 12
            ),
            rowsStack.bottomAnchor.constraint(
                equalTo: card.bottomAnchor,
                constant: -12
            ),
            rowsStack.leadingAnchor.constraint(
                equalTo: card.leadingAnchor,
                constant: 16
            ),
            rowsStack.trailingAnchor.constraint(
                equalTo: card.trailingAnchor,
                constant: -16
            )
        ])

        let contentStack = UIStackView(arrangedSubviews: [
            headerStack,
            card
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        configure(users: [])
    }

    func configure(users: [HomeRecentFavoriteViewModel]) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard !users.isEmpty else {
            let emptyLabel = UILabel()
            emptyLabel.text = "No favorites yet."
            emptyLabel.font = .systemFont(ofSize: 14)
            emptyLabel.textColor = AppTheme.Colors.secondaryText
            emptyLabel.textAlignment = .center

            rowsStack.addArrangedSubview(emptyLabel)
            emptyLabel.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 64
            ).isActive = true
            return
        }

        for (index, user) in users.enumerated() {
            if index > 0 {
                let separator = UIView()
                separator.backgroundColor = AppTheme.Colors.border
                    .withAlphaComponent(0.25)

                rowsStack.addArrangedSubview(separator)
                separator.heightAnchor.constraint(
                    equalToConstant: 1 / UIScreen.main.scale
                ).isActive = true
            }

            rowsStack.addArrangedSubview(makeRow(for: user))
        }
    }

    private func makeRow(
        for user: HomeRecentFavoriteViewModel
    ) -> UIView {
        let avatarImageView = UIImageView()
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.tintColor = AppTheme.Colors.secondaryText
        avatarImageView.image = UIImage(
            systemName: "person.crop.circle.fill"
        )
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        if let url = user.avatarURL {
            avatarImageView.kf.setImage(with: url)
        }

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44)
        ])

        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = AppTheme.Colors.primaryText
        nameLabel.lineBreakMode = .byTruncatingTail

        let usernameLabel = UILabel()
        usernameLabel.text = "@\(user.username)"
        usernameLabel.font = .systemFont(ofSize: 13)
        usernameLabel.textColor = AppTheme.Colors.secondaryText
        usernameLabel.lineBreakMode = .byTruncatingMiddle

        let textStack = UIStackView(arrangedSubviews: [
            nameLabel,
            usernameLabel
        ])
        textStack.axis = .vertical
        textStack.spacing = 4

        let heartImageView = UIImageView(
            image: UIImage(systemName: "heart.fill")
        )
        heartImageView.tintColor = AppTheme.Colors.accent
        heartImageView.contentMode = .scaleAspectFit
        heartImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heartImageView.widthAnchor.constraint(equalToConstant: 18),
            heartImageView.heightAnchor.constraint(equalToConstant: 18)
        ])

        let row = UIStackView(arrangedSubviews: [
            avatarImageView,
            textStack,
            heartImageView
        ])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 12,
            leading: 0,
            bottom: 12,
            trailing: 0
        )

        return row
    }

    @objc private func seeAllTapped() {
        onSeeAllTapped?()
    }
}
