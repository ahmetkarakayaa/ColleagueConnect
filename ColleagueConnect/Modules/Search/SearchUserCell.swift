import UIKit
import Kingfisher

final class SearchUserCell: UICollectionViewCell {
    static let reuseIdentifier = "SearchUserCell"


    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 32
        imageView.tintColor = .tertiaryLabel
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = AppTheme.Colors.primaryText
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()

    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = AppTheme.Colors.accent
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()

    private lazy var bioLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.isHidden = true
        return label
    }()

    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = AppTheme.Colors.accent
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = UIEdgeInsets(
            top: 4,
            left: 4,
            bottom: 4,
            right: 4
        )
        button.addTarget(
            self,
            action: #selector(favoriteButtonTapped),
            for: .touchUpInside
        )
        return button
    }()
    private let burstLayer = CAShapeLayer()
    private var representedUsername: String?
    var onFavoriteTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.kf.cancelDownloadTask()
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        representedUsername = nil
        nameLabel.text = nil
        usernameLabel.text = nil
        bioLabel.text = nil
        bioLabel.isHidden = true
        onFavoriteTapped = nil
        burstLayer.removeAllAnimations()
        burstLayer.path = nil
        favoriteButton.layer.removeAllAnimations()
        favoriteButton.transform = .identity
    }

    func configure(with user: SearchUserViewModel, isFavorite: Bool = false) {
        configureProfile(username: user.username, avatarURL: user.avatarURL, isFavorite: isFavorite)
    }

    func configureFavorite(with user: FavoriteUserViewModel) {
        configureProfile(username: user.username, avatarURL: user.avatarURL, isFavorite: true)
    }

    private func configureProfile(username: String, avatarURL: URL?, isFavorite: Bool) {
        representedUsername = username
        nameLabel.text = username
        usernameLabel.text = "@\(username)"
        bioLabel.text = nil
        bioLabel.isHidden = true
        updateFavoriteIcon(isFavorite: isFavorite)
        avatarImageView.kf.setImage(
            with: avatarURL,
            placeholder: UIImage(systemName: "person.crop.circle.fill")
        )
    }

    func configureDetails(username: String, name: String?, bio: String?) {
        guard representedUsername == username else { return }
        let cleanName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBio = bio?.trimmingCharacters(in: .whitespacesAndNewlines)
        nameLabel.text = (cleanName?.isEmpty == false) ? cleanName : username
        bioLabel.text = cleanBio
        bioLabel.isHidden = cleanBio?.isEmpty != false
    }

    func updateFavorite(isFavorite: Bool, animated: Bool) {
        guard animated else {
            updateFavoriteIcon(isFavorite: isFavorite)
            return
        }
        if isFavorite {
            playFavoriteAnimation()
        } else {
            UIView.animate(withDuration: 0.18, animations: {
                self.favoriteButton.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
            }, completion: { _ in
                self.updateFavoriteIcon(isFavorite: false)
                UIView.animate(withDuration: 0.18) { self.favoriteButton.transform = .identity }
            })
        }
    }

    private func updateFavoriteIcon(isFavorite: Bool) {
        let image = isFavorite
            ? UIImage(named: "n11HeartFilled")?.withRenderingMode(.alwaysOriginal)
            : UIImage(systemName: "heart")
        favoriteButton.setImage(image, for: .normal)
        favoriteButton.tintColor = AppTheme.Colors.accent
        favoriteButton.imageView?.contentMode = .scaleAspectFit
    }

    private func playFavoriteAnimation() {
        guard let finalImage = UIImage(named: "n11HeartFilled") else {
            favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            return
        }
        favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        favoriteButton.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: [.allowUserInteraction],
            animations: {
                self.favoriteButton.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
            },
            completion: { _ in
                UIView.transition(with: self.favoriteButton, duration: 0.22,
                                  options: .transitionCrossDissolve, animations: {
                    self.favoriteButton.setImage(finalImage.withRenderingMode(.alwaysOriginal), for: .normal)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.15) { self.favoriteButton.transform = .identity }
                })
            }
        )
        playBurstAnimation()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func playBurstAnimation() {
        burstLayer.removeAllAnimations()
        burstLayer.path = nil
        let center = CGPoint(x: 22, y: 22)
        let path = UIBezierPath()
        for index in 0..<10 {
            let angle = CGFloat(index) * (.pi * 2 / 10)
            path.move(to: CGPoint(x: center.x + cos(angle) * 18, y: center.y + sin(angle) * 18))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * 24, y: center.y + sin(angle) * 24))
        }
        burstLayer.path = path.cgPath
        burstLayer.strokeColor = UIColor.label.cgColor
        burstLayer.fillColor = UIColor.clear.cgColor
        burstLayer.lineWidth = 1.7
        burstLayer.lineCap = .round
        burstLayer.frame = favoriteButton.bounds
        if burstLayer.superlayer == nil { favoriteButton.layer.addSublayer(burstLayer) }
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = 0.38
        burstLayer.add(animation, forKey: "fade")
        burstLayer.opacity = 0
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        layer.cornerRadius = 18
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.055
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.masksToBounds = false

        [avatarImageView, nameLabel, usernameLabel, bioLabel, favoriteButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            favoriteButton.widthAnchor.constraint(equalToConstant: 40),
            favoriteButton.heightAnchor.constraint(equalToConstant: 40),
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 64),
            avatarImageView.heightAnchor.constraint(equalToConstant: 64),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            bioLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 6),
            bioLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            bioLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            bioLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    @objc private func favoriteButtonTapped() { onFavoriteTapped?() }
}
