
import UIKit
import Kingfisher

@MainActor
final class RecentlyViewedViewController: UIViewController {

    private struct Profile {
        let username: String
        var name: String
        var avatarURL: URL?
    }

    private let storage: RecentlyViewedStorageServiceProtocol
    private let networkClient: NetworkClientProtocol
    private let authService: AuthServiceProtocol
    private let onSelectProfile: (String) -> Void

    private var profiles: [Profile] = []
    private var loadTasks: [Task<Void, Never>] = []
    private var loadGeneration = 0

    private static var profileCache: [String: Profile] = [:]

    private let countLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let clearButton = UIBarButtonItem(
        title: "Clear All",
        style: .plain,
        target: nil,
        action: nil
    )

    init(
        storage: RecentlyViewedStorageServiceProtocol,
        networkClient: NetworkClientProtocol,
        authService: AuthServiceProtocol,
        onSelectProfile: @escaping (String) -> Void
    ) {
        self.storage = storage
        self.networkClient = networkClient
        self.authService = authService
        self.onSelectProfile = onSelectProfile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Recently Viewed"
        view.backgroundColor = AppTheme.Colors.background
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadHistory()
    }

    private func setupUI() {
        clearButton.target = self
        clearButton.action = #selector(clearTapped)
        clearButton.tintColor = .systemRed
        navigationItem.rightBarButtonItem = clearButton

        countLabel.font = .systemFont(ofSize: 14)
        countLabel.textColor = AppTheme.Colors.secondaryText
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 76
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            RecentlyViewedCell.self,
            forCellReuseIdentifier: RecentlyViewedCell.reuseID
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(countLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 20
            ),
            countLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 22
            ),
            countLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -22
            ),

            tableView.topAnchor.constraint(
                equalTo: countLabel.bottomAnchor,
                constant: 16
            ),
            tableView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 22
            ),
            tableView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -22
            ),
            tableView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            )
        ])
    }


    private func cancelLoading() {
        loadGeneration += 1

        loadTasks.forEach { $0.cancel() }
        loadTasks.removeAll()
    }

    private func reloadHistory() {
        cancelLoading()

        let usernames = storage.getRecentlyViewed(limit: nil)

        profiles = usernames.map { username in
            Self.profileCache[username.lowercased()]
                ?? Profile(
                    username: username,
                    name: username,
                    avatarURL: nil
                )
        }

        updateUI()

        let pending = usernames.filter {
            Self.profileCache[$0.lowercased()] == nil
        }

        guard !pending.isEmpty else { return }

        guard let token = try? authService.accessToken(),
              !token.isEmpty else {
            return
        }

        let generation = loadGeneration
        let workerCount = min(4, pending.count)

        for workerIndex in 0..<workerCount {
            let task = Task { [weak self] in
                guard let self else { return }

                for index in stride(
                    from: workerIndex,
                    to: pending.count,
                    by: workerCount
                ) {
                    guard !Task.isCancelled,
                          self.loadGeneration == generation else {
                        return
                    }

                    let username = pending[index]

                    do {
                        let dto: UserDetailDTO =
                            try await self.networkClient.request(
                                endpoint: GitHubEndpoint.authenticatedUserDetail(
                                    username: username,
                                    token: token
                                )
                            )

                        try Task.checkCancellation()

                        guard self.loadGeneration == generation else {
                            return
                        }

                        let user = dto.toEntity()

                        let resolvedProfile = Profile(
                            username: username,
                            name: user.name?.isEmpty == false
                                ? user.name!
                                : user.login,
                            avatarURL: user.avatarURL
                        )

                        Self.profileCache[username.lowercased()] =
                            resolvedProfile

                        guard let currentIndex = self.profiles.firstIndex(
                            where: {
                                $0.username.caseInsensitiveCompare(
                                    username
                                ) == .orderedSame
                            }
                        ) else {
                            continue
                        }

                        self.profiles[currentIndex] = resolvedProfile

                        self.tableView.reloadRows(
                            at: [
                                IndexPath(
                                    row: currentIndex,
                                    section: 0
                                )
                            ],
                            with: .none
                        )
                    } catch is CancellationError {
                        return
                    } catch {
                        continue
                    }
                }
            }

            loadTasks.append(task)
        }
    }


    private func updateUI() {
        let count = profiles.count
        countLabel.text = "\(count) profiles viewed"
        clearButton.isEnabled = count > 0

        if count == 0 {
            let label = UILabel()
            label.text = "No profiles viewed yet."
            label.textColor = AppTheme.Colors.secondaryText
            label.textAlignment = .center
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }

        tableView.reloadData()
    }

    @objc private func clearTapped() {
        let alert = UIAlertController(
            title: "Clear History?",
            message: "All recently viewed profiles will be removed.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel)
        )

        alert.addAction(
            UIAlertAction(title: "Clear All", style: .destructive) {
                [weak self] _ in
                guard let self else { return }

                self.cancelLoading()
                self.storage.clearHistory()
                Self.profileCache.removeAll()
                self.profiles.removeAll()
                self.updateUI()
            }
        )

        present(alert, animated: true)
    }

    deinit {
        loadTasks.forEach { $0.cancel() }
    }
}

extension RecentlyViewedViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        profiles.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: RecentlyViewedCell.reuseID,
            for: indexPath
        ) as? RecentlyViewedCell else {
            return UITableViewCell()
        }

        let profile = profiles[indexPath.row]
        cell.configure(
            name: profile.name,
            username: profile.username,
            avatarURL: profile.avatarURL
        )
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelectProfile(profiles[indexPath.row].username)
    }
}

@MainActor
private final class RecentlyViewedCell: UITableViewCell {

    static let reuseID = "RecentlyViewedCell"

    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 22
        avatarView.backgroundColor = .systemGray6
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = AppTheme.Colors.primaryText
        nameLabel.lineBreakMode = .byTruncatingTail

        usernameLabel.font = .systemFont(ofSize: 13)
        usernameLabel.textColor = AppTheme.Colors.secondaryText
        usernameLabel.lineBreakMode = .byTruncatingMiddle

        let labels = UIStackView(arrangedSubviews: [
            nameLabel, usernameLabel
        ])
        labels.axis = .vertical
        labels.spacing = 4

        let stack = UIStackView(arrangedSubviews: [
            avatarView, labels
        ])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        accessoryType = .disclosureIndicator

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),

            stack.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 8
            ),
            stack.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -8
            ),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.kf.cancelDownloadTask()
        avatarView.image = nil
    }

    func configure(name: String, username: String, avatarURL: URL?) {
        nameLabel.text = name
        usernameLabel.text = "@\(username)"
        avatarView.kf.setImage(with: avatarURL)
    }
}
