
import UIKit
import Kingfisher

final class SearchUserCell: UICollectionViewCell {

    static let reuseIdentifier = "SearchUserCell"

    private let avatarImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let favoriteButton = UIButton(type: .custom)

    private let burstLayer = CAShapeLayer()

    var onFavoriteTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.kf.cancelDownloadTask()
        avatarImageView.image = UIImage(
            systemName: "person.crop.circle.fill"
        )

        usernameLabel.text = nil
        onFavoriteTapped = nil

        burstLayer.removeAllAnimations()
        burstLayer.path = nil
        favoriteButton.layer.removeAllAnimations()
    }

    func configure(
        with user: SearchUserViewModel,
        isFavorite: Bool = false
    ) {
        usernameLabel.text = user.username

        updateFavoriteIcon(isFavorite: isFavorite)

        avatarImageView.kf.setImage(
            with: user.avatarURL,
            placeholder: UIImage(
                systemName: "person.crop.circle.fill"
            )
        )
    }
    
    func configureFavorite(with user: FavoriteUserViewModel) {
        usernameLabel.text = user.username

        updateFavoriteIcon(isFavorite: true)

        avatarImageView.kf.setImage(
            with: user.avatarURL,
            placeholder: UIImage(
                systemName: "person.crop.circle.fill"
            )
        )
    }


    func updateFavorite(
        isFavorite: Bool,
        animated: Bool
    ) {
        updateFavoriteIcon(isFavorite: isFavorite)

        guard animated else { return }

        if isFavorite {
            playFavoriteAnimation()
        } else {
            UIView.animate(
                withDuration: 0.18,
                animations: {
                    self.favoriteButton.transform =
                        CGAffineTransform(scaleX: 0.82, y: 0.82)
                },
                completion: { _ in
                    UIView.animate(withDuration: 0.18) {
                        self.favoriteButton.transform = .identity
                    }
                }
            )
        }
    }

    private func updateFavoriteIcon(isFavorite: Bool) {
        if isFavorite {
            favoriteButton.setImage(
                UIImage(named: "n11Favorite"),
                for: .normal
            )
        } else {
            favoriteButton.setImage(
                UIImage(systemName: "heart"),
                for: .normal
            )
        }
    }

    private func playFavoriteAnimation() {
        favoriteButton.transform =
            CGAffineTransform(scaleX: 0.65, y: 0.65)

        UIView.animate(
            withDuration: 0.38,
            delay: 0,
            usingSpringWithDamping: 0.55,
            initialSpringVelocity: 0.4,
            options: [.allowUserInteraction],
            animations: {
                self.favoriteButton.transform = .identity
            }
        )

        playBurstAnimation()

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }

    private func playBurstAnimation() {
        burstLayer.removeAllAnimations()
        burstLayer.path = nil

        let center = CGPoint(x: 22, y: 22)
        let path = UIBezierPath()

        for index in 0..<10 {
            let angle = CGFloat(index) * (.pi * 2 / 10)

            let innerRadius: CGFloat = 18
            let outerRadius: CGFloat = 24

            let start = CGPoint(
                x: center.x + cos(angle) * innerRadius,
                y: center.y + sin(angle) * innerRadius
            )

            let end = CGPoint(
                x: center.x + cos(angle) * outerRadius,
                y: center.y + sin(angle) * outerRadius
            )

            path.move(to: start)
            path.addLine(to: end)
        }

        burstLayer.path = path.cgPath
        burstLayer.strokeColor = UIColor.label.cgColor
        burstLayer.fillColor = UIColor.clear.cgColor
        burstLayer.lineWidth = 1.7
        burstLayer.lineCap = .round
        burstLayer.frame = favoriteButton.bounds

        if burstLayer.superlayer == nil {
            favoriteButton.layer.addSublayer(burstLayer)
        }

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = 0.38

        burstLayer.add(animation, forKey: "fade")
        burstLayer.opacity = 0
    }

    private func setupUI() {
        contentView.backgroundColor = AppTheme.Colors.surface
        contentView.layer.cornerRadius = AppTheme.Radius.card
        contentView.layer.masksToBounds = true

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.tintColor = .tertiaryLabel

        usernameLabel.font = .systemFont(
            ofSize: 15,
            weight: .semibold
        )
        usernameLabel.textColor = AppTheme.Colors.primaryText
        usernameLabel.textAlignment = .center
        usernameLabel.lineBreakMode = .byTruncatingTail

        
        favoriteButton.tintColor = AppTheme.Colors.accent
        favoriteButton.setImage(
            UIImage(systemName: "heart"),
            for: .normal
        )

        favoriteButton.imageView?.contentMode = .scaleAspectFit

        favoriteButton.addTarget(
            self,
            action: #selector(favoriteButtonTapped),
            for: .touchUpInside
        )


        let textStack = UIStackView(
            arrangedSubviews: [usernameLabel]
        )

        textStack.axis = .vertical
        textStack.alignment = .fill


        [
            avatarImageView,
            textStack,
            favoriteButton
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            favoriteButton.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 8
            ),
            favoriteButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -8
            ),
            favoriteButton.widthAnchor.constraint(
                equalToConstant: 44
            ),
            favoriteButton.heightAnchor.constraint(
                equalToConstant: 44
            ),

            avatarImageView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 34
            ),
            avatarImageView.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor
            ),
            avatarImageView.widthAnchor.constraint(
                equalToConstant: 84
            ),
            avatarImageView.heightAnchor.constraint(
                equalToConstant: 84
            ),

            textStack.topAnchor.constraint(
                equalTo: avatarImageView.bottomAnchor,
                constant: 9
            ),
            textStack.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 12
            ),
            textStack.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -12
            ),
            textStack.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -10
            )
        ])
    }

    @objc private func favoriteButtonTapped() {
        onFavoriteTapped?()
    }
}
