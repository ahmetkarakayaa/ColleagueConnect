
import UIKit

final class WelcomeViewController: UIViewController {

    var presenter: WelcomeViewOutput?

    private let backgroundColor = UIColor(
        red: 1,
        green: 0.99,
        blue: 1,
        alpha: 1
    )

    private let magenta = UIColor(
        red: 0.96,
        green: 0.04,
        blue: 0.62,
        alpha: 1
    )

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(named: "colleagueConnectLogo")
        )
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.65
        label.translatesAutoresizingMaskIntoConstraints = false

        let title = NSMutableAttributedString(
            string: "Colleague",
            attributes: [
                .foregroundColor: UIColor(
                    red: 0.06,
                    green: 0.08,
                    blue: 0.13,
                    alpha: 1
                ),
                .font: UIFont.systemFont(ofSize: 34, weight: .bold)
            ]
        )

        title.append(
            NSAttributedString(
                string: "Connect",
                attributes: [
                    .foregroundColor: UIColor(
                        red: 0.96,
                        green: 0.04,
                        blue: 0.62,
                        alpha: 1
                    ),
                    .font: UIFont.systemFont(ofSize: 34, weight: .bold)
                ]
            )
        )

        label.attributedText = title
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(
            red: 0.61,
            green: 0.64,
            blue: 0.70,
            alpha: 1
        )
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with GitHub", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white, for: .disabled)
        button.titleLabel?.font = .systemFont(
            ofSize: 17,
            weight: .semibold
        )
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "githubLoginButton"
        button.isEnabled = false
        return button
    }()

    private let githubIcon: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(named: "githubIcon")?
                .withRenderingMode(.alwaysTemplate)
        )
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(
            red: 0.10,
            green: 0.11,
            blue: 0.18,
            alpha: 1
        )
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let iconBackground: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 19
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let arrowIcon: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(systemName: "arrow.right")
        )
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let buttonGradient = CAGradientLayer()
    private let topCircle = UIView()
    private let bottomCircle = UIView()
    private let topArc = CAShapeLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        presenter?.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        buttonGradient.frame = loginButton.bounds
        topArc.frame = view.bounds

        let path = UIBezierPath(
            arcCenter: CGPoint(
                x: view.bounds.width * 1.05,
                y: -view.bounds.width * 0.29
            ),
            radius: view.bounds.width * 0.82,
            startAngle: .pi * 0.22,
            endAngle: .pi * 0.94,
            clockwise: true
        )

        topArc.path = path.cgPath
    }

    private func setupUI() {
        view.backgroundColor = backgroundColor

        setupDecorations()
        setupContent()
        setupButton()
    }

    private func setupDecorations() {
        topCircle.backgroundColor = magenta.withAlphaComponent(0.22)
        topCircle.translatesAutoresizingMaskIntoConstraints = false
        topCircle.layer.cornerRadius = 185
        topCircle.isUserInteractionEnabled = false

        bottomCircle.backgroundColor = magenta.withAlphaComponent(0.06)
        bottomCircle.translatesAutoresizingMaskIntoConstraints = false
        bottomCircle.layer.cornerRadius = 230
        bottomCircle.isUserInteractionEnabled = false

        view.addSubview(topCircle)
        view.addSubview(bottomCircle)

        topArc.strokeColor = magenta.withAlphaComponent(0.7).cgColor
        topArc.fillColor = UIColor.clear.cgColor
        topArc.lineWidth = 1
        view.layer.addSublayer(topArc)

        NSLayoutConstraint.activate([
            topCircle.widthAnchor.constraint(equalToConstant: 370),
            topCircle.heightAnchor.constraint(equalToConstant: 370),
            topCircle.leadingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -145
            ),
            topCircle.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: -120
            ),

            bottomCircle.widthAnchor.constraint(equalToConstant: 460),
            bottomCircle.heightAnchor.constraint(equalToConstant: 460),
            bottomCircle.trailingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 200
            ),
            bottomCircle.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: 150
            )
        ])
    }

    private func setupContent() {
        let contentStack = UIStackView(arrangedSubviews: [
            logoImageView,
            titleLabel,
            subtitleLabel
        ])

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.setCustomSpacing(22, after: logoImageView)
        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            contentStack.centerYAnchor.constraint(
                equalTo: view.centerYAnchor,
                constant: -40
            ),
            contentStack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24
            ),
            logoImageView.heightAnchor.constraint(equalToConstant: 220),
            titleLabel.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupButton() {
        view.addSubview(loginButton)

        buttonGradient.colors = [
            UIColor(
                red: 0.10,
                green: 0.11,
                blue: 0.18,
                alpha: 1
            ).cgColor,
            magenta.cgColor
        ]

        buttonGradient.startPoint = CGPoint(x: 0, y: 0.5)
        buttonGradient.endPoint = CGPoint(x: 1, y: 0.5)

        loginButton.layer.insertSublayer(buttonGradient, at: 0)

        NSLayoutConstraint.activate([
            loginButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 28
            ),
            loginButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -28
            ),
            loginButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -42
            ),
            loginButton.heightAnchor.constraint(equalToConstant: 64)
        ])

        loginButton.addSubview(iconBackground)
        loginButton.addSubview(githubIcon)
        loginButton.addSubview(arrowIcon)
        loginButton.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            githubIcon.leadingAnchor.constraint(
                equalTo: loginButton.leadingAnchor,
                constant: 22
            ),
            githubIcon.centerYAnchor.constraint(
                equalTo: loginButton.centerYAnchor
            ),
            githubIcon.widthAnchor.constraint(equalToConstant: 28),
            githubIcon.heightAnchor.constraint(equalToConstant: 28),

            iconBackground.centerXAnchor.constraint(
                equalTo: githubIcon.centerXAnchor
            ),
            iconBackground.centerYAnchor.constraint(
                equalTo: githubIcon.centerYAnchor
            ),
            iconBackground.widthAnchor.constraint(equalToConstant: 38),
            iconBackground.heightAnchor.constraint(equalToConstant: 38),

            arrowIcon.trailingAnchor.constraint(
                equalTo: loginButton.trailingAnchor,
                constant: -22
            ),
            arrowIcon.centerYAnchor.constraint(
                equalTo: loginButton.centerYAnchor
            ),
            arrowIcon.widthAnchor.constraint(equalToConstant: 22),
            arrowIcon.heightAnchor.constraint(equalToConstant: 22),

            activityIndicator.centerXAnchor.constraint(
                equalTo: loginButton.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: loginButton.centerYAnchor
            )
        ])
    }

    private func updateLoadingState(_ isLoading: Bool) {
        loginButton.isEnabled = false
        loginButton.titleLabel?.isHidden = isLoading
        githubIcon.isHidden = isLoading
        iconBackground.isHidden = isLoading
        arrowIcon.isHidden = isLoading

        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}

extension WelcomeViewController: WelcomeViewInput {

    func displayWelcomeMessage(_ message: String) {
        subtitleLabel.text = message
    }

    func setLoading(_ isLoading: Bool) {
        updateLoadingState(isLoading)
    }

    func displayError(_ message: String) {
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(
            title: "Sign In Failed",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            )
        )

        present(alert, animated: true)
    }
}
