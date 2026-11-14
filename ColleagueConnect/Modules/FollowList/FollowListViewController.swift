
import UIKit
import Kingfisher

@MainActor
final class FollowListViewController: UIViewController, FollowListViewInput {

    var presenter: FollowListViewOutput?

    private let listType: FollowListType
    private let appBackgroundView = AppBackgroundView()

    private var users: [FollowListUserViewModel] = []

    private enum Layout {
        static let horizontalInset: CGFloat = 22
        static let rowHeight: CGFloat = 76
    }

    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = Layout.rowHeight
        table.contentInset = UIEdgeInsets(
            top: 12,
            left: 0,
            bottom: 32,
            right: 0
        )

        table.dataSource = self
        table.delegate = self

        table.register(
            FollowListCell.self,
            forCellReuseIdentifier: FollowListCell.reuseIdentifier
        )

        table.isHidden = true
        return table
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15)
        label.textColor = AppTheme.Colors.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    init(type: FollowListType) {
        self.listType = type
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = listType.title
        view.backgroundColor = AppTheme.Colors.background
        navigationItem.largeTitleDisplayMode = .never

        setupHierarchy()
        setupConstraints()

        presenter?.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }


    private func setupHierarchy() {
        appBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(appBackgroundView)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(messageLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            appBackgroundView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            appBackgroundView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
            appBackgroundView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            appBackgroundView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),

            tableView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            tableView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Layout.horizontalInset
            ),
            tableView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Layout.horizontalInset
            ),
            tableView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),

            activityIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),

            messageLabel.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            messageLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 32
            ),
            messageLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -32
            )
        ])
    }

    func displayLoading() {
        tableView.isHidden = true
        messageLabel.isHidden = true
        activityIndicator.startAnimating()
    }

    func displayUsers(_ users: [FollowListUserViewModel]) {
        self.users = users

        activityIndicator.stopAnimating()
        tableView.reloadData()

        let isEmpty = users.isEmpty

        tableView.isHidden = isEmpty
        messageLabel.isHidden = !isEmpty

        if isEmpty {
            messageLabel.text = listType == .followers
                ? "No followers yet."
                : "Not following anyone yet."
        }
    }

    func displayError(_ message: String) {
        activityIndicator.stopAnimating()
        tableView.isHidden = true

        messageLabel.text = message
        messageLabel.isHidden = false
    }

    func displayPageError(_ message: String) {
        let alert = UIAlertController(
            title: "Loading Error",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Retry",
                style: .default
            ) { [weak self] _ in
                self?.presenter?.didReachEnd()
            }
        )

        alert.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel
            )
        )

        present(alert, animated: true)
    }

}

extension FollowListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        users.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FollowListCell.reuseIdentifier,
            for: indexPath
        ) as? FollowListCell else {
            return UITableViewCell()
        }

        cell.configure(with: users[indexPath.row])
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(
            at: indexPath,
            animated: true
        )

        presenter?.didSelectUser(at: indexPath.row)
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard !users.isEmpty,
              indexPath.row >= users.count - 5 else {
            return
        }

        presenter?.didReachEnd()
    }

}


private final class FollowListCell: UITableViewCell {

    static let reuseIdentifier = "FollowListCell"

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let chevronImageView = UIImageView()
    private let separatorView = UIView()

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 24
        avatarImageView.backgroundColor = AppTheme.Colors.surface

        nameLabel.font = .systemFont(
            ofSize: 16,
            weight: .semibold
        )
        nameLabel.textColor = AppTheme.Colors.primaryText
        nameLabel.lineBreakMode = .byTruncatingTail

        usernameLabel.font = .systemFont(ofSize: 13)
        usernameLabel.textColor = AppTheme.Colors.secondaryText
        usernameLabel.lineBreakMode = .byTruncatingTail

        let labelsStack = UIStackView(
            arrangedSubviews: [
                nameLabel,
                usernameLabel
            ]
        )
        labelsStack.axis = .vertical
        labelsStack.alignment = .fill
        labelsStack.spacing = 4
        labelsStack.translatesAutoresizingMaskIntoConstraints = false

        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(
            systemName: "chevron.right"
        )
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = UIColor.systemGray5

        contentView.addSubview(avatarImageView)
        contentView.addSubview(labelsStack)
        contentView.addSubview(chevronImageView)
        contentView.addSubview(separatorView)

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 4
            ),
            avatarImageView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            avatarImageView.widthAnchor.constraint(
                equalToConstant: 48
            ),
            avatarImageView.heightAnchor.constraint(
                equalToConstant: 48
            ),

            labelsStack.leadingAnchor.constraint(
                equalTo: avatarImageView.trailingAnchor,
                constant: 14
            ),
            labelsStack.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            labelsStack.trailingAnchor.constraint(
                lessThanOrEqualTo: chevronImageView.leadingAnchor,
                constant: -12
            ),

            chevronImageView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -8
            ),
            chevronImageView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            chevronImageView.widthAnchor.constraint(
                equalToConstant: 12
            ),
            chevronImageView.heightAnchor.constraint(
                equalToConstant: 18
            ),

            separatorView.leadingAnchor.constraint(
                equalTo: labelsStack.leadingAnchor
            ),
            separatorView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -8
            ),
            separatorView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            ),
            separatorView.heightAnchor.constraint(
                equalToConstant: 0.5
            )
        ])

        labelsStack.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
    }

    func configure(with user: FollowListUserViewModel) {
        nameLabel.text = user.name
        usernameLabel.text = "@\(user.username)"

        avatarImageView.kf.setImage(
            with: user.avatarURL,
            options: [.transition(.fade(0.2))]
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.kf.cancelDownloadTask()
        avatarImageView.image = nil
        nameLabel.text = nil
        usernameLabel.text = nil
    }
}
