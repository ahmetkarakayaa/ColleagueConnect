import UIKit
import Kingfisher

@MainActor
final class HomeRecentlyViewedView: UIView {

    var onSeeAllTapped: (() -> Void)?
    var onProfileTapped: ((String) -> Void)?

    private let rowsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let titleLabel = UILabel()
        titleLabel.text = "Recently Viewed"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = AppTheme.Colors.primaryText

        let seeAllButton = UIButton(type: .system)
        seeAllButton.setTitle("See All", for: .normal)
        seeAllButton.setTitleColor(AppTheme.Colors.accent, for: .normal)
        seeAllButton.titleLabel?.font = .systemFont(
            ofSize: 14,
            weight: .semibold
        )
        seeAllButton.addAction(
            UIAction { [weak self] _ in self?.onSeeAllTapped?() },
            for: .touchUpInside
        )
        let historyIcon = UIImageView(
            image: UIImage(systemName: "clock.arrow.circlepath")
        )

        historyIcon.tintColor = AppTheme.Colors.accent
        historyIcon.contentMode = .scaleAspectFit
        historyIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            historyIcon.widthAnchor.constraint(equalToConstant: 19),
            historyIcon.heightAnchor.constraint(equalToConstant: 19)
        ])

        let titleStack = UIStackView(arrangedSubviews: [
            titleLabel,
            historyIcon
        ])

        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 8

        let header = UIStackView(arrangedSubviews: [
            titleStack,
            seeAllButton
        ])
        header.axis = .horizontal
        header.alignment = .center
        header.distribution = .equalSpacing

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = AppTheme.Radius.card
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.systemGray5.cgColor

        rowsStack.axis = .vertical
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rowsStack)

        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            rowsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            rowsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            rowsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])

        let stack = UIStackView(arrangedSubviews: [header, card])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        configure(users: [])
    }

    func configure(users: [HomeRecentFavoriteViewModel]) {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard !users.isEmpty else {
            let label = UILabel()
            label.text = "No profiles viewed yet."
            label.font = .systemFont(ofSize: 14)
            label.textColor = AppTheme.Colors.secondaryText
            label.textAlignment = .center
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
            rowsStack.addArrangedSubview(label)
            return
        }

        for (index, user) in users.enumerated() {
            if index > 0 {
                let divider = UIView()
                divider.backgroundColor = UIColor.systemGray5
                divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
                rowsStack.addArrangedSubview(divider)
            }

            let button = UIButton(type: .custom)
            button.accessibilityLabel = "View \(user.name) profile"

            let avatar = UIImageView()
            avatar.contentMode = .scaleAspectFill
            avatar.clipsToBounds = true
            avatar.layer.cornerRadius = 22
            avatar.backgroundColor = .systemGray6
            avatar.kf.setImage(with: user.avatarURL)
            avatar.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                avatar.widthAnchor.constraint(equalToConstant: 44),
                avatar.heightAnchor.constraint(equalToConstant: 44)
            ])

            let name = UILabel()
            name.text = user.name
            name.font = .systemFont(ofSize: 15, weight: .semibold)
            name.textColor = AppTheme.Colors.primaryText

            let username = UILabel()
            username.text = "@\(user.username)"
            username.font = .systemFont(ofSize: 13)
            username.textColor = AppTheme.Colors.secondaryText

            let labels = UIStackView(arrangedSubviews: [name, username])
            labels.axis = .vertical
            labels.spacing = 4

            let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrow.tintColor = .tertiaryLabel
            arrow.setContentHuggingPriority(.required, for: .horizontal)

            let row = UIStackView(arrangedSubviews: [avatar, labels, arrow])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            row.isLayoutMarginsRelativeArrangement = true
            row.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 12, leading: 0, bottom: 12, trailing: 0
            )
            row.isUserInteractionEnabled = false
            button.addSubview(row)
            row.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: button.topAnchor),
                row.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                row.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: button.trailingAnchor)
            ])

            button.addAction(
                UIAction { [weak self] _ in
                    self?.onProfileTapped?(user.username)
                },
                for: .touchUpInside
            )

            rowsStack.addArrangedSubview(button)
        }
    }
}
