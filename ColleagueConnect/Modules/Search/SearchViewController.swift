import UIKit

final class SearchViewController: UIViewController {

    var presenter: SearchViewOutput?


    private enum Section: Hashable {
        case main
    }

    private enum SortOption {
        case defaultOrder
        case alphabetical
        case reverseAlphabetical
    }

    private enum Layout {
        static let headerHeight: CGFloat = 126
    }


    private var sortOption: SortOption = .defaultOrder
    private var currentUsers: [SearchUserViewModel] = []
    private var isSearchActive = false


    private lazy var headerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.2.fill"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = AppTheme.Colors.accent
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var brandLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let text = NSMutableAttributedString(
            string: "Colleague",
            attributes: [
                .font: UIFont.systemFont(ofSize: 19, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
        text.append(NSAttributedString(
            string: "Connect",
            attributes: [
                .font: UIFont.systemFont(ofSize: 19, weight: .bold),
                .foregroundColor: AppTheme.Colors.accent
            ]
        ))
        label.attributedText = text
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Search"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .label
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Discover and connect with developers."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()


    private lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.delegate = self
        bar.placeholder = "Username"
        bar.searchBarStyle = .minimal
        bar.backgroundImage = UIImage()

        let field = bar.searchTextField
        field.backgroundColor = .white
        field.borderStyle = .none
        field.layer.cornerRadius = 15
        field.layer.borderWidth = 1.5
        field.layer.borderColor = AppTheme.Colors.accent.cgColor
        field.layer.masksToBounds = true
        field.textColor = .black
        field.tintColor = AppTheme.Colors.accent
        field.leftView?.tintColor = AppTheme.Colors.accent
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .search
        return bar
    }()

    private lazy var resultsRow: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var resultsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Find people"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sort: Default", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.tintColor = .secondaryLabel
        button.menu = UIMenu(children: [
            UIAction(title: "Default order") { [weak self] _ in
                self?.applySort(.defaultOrder, title: "Sort: Default")
            },
            UIAction(title: "Username A–Z") { [weak self] _ in
                self?.applySort(.alphabetical, title: "Sort: A–Z")
            },
            UIAction(title: "Username Z–A") { [weak self] _ in
                self?.applySort(.reverseAlphabetical, title: "Sort: Z–A")
            }
        ])
        button.showsMenuAsPrimaryAction = true
        return button
    }()


    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: createLayout()
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = true
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = true
        collectionView.keyboardDismissMode = .interactive
        collectionView.register(
            SearchUserCell.self,
            forCellWithReuseIdentifier: SearchUserCell.reuseIdentifier
        )
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, SearchUserViewModel> = {
        UICollectionViewDiffableDataSource<Section, SearchUserViewModel>(
            collectionView: self.collectionView
        ) { [weak self] collectionView, indexPath, user in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SearchUserCell.reuseIdentifier,
                for: indexPath
            ) as? SearchUserCell else {
                return UICollectionViewCell()
            }

            guard let self else { return cell }

            cell.configure(
                with: user,
                isFavorite: self.presenter?.isFavorite(username: user.username) ?? false
            )

            cell.onFavoriteTapped = { [weak self, weak cell] in
                guard let self, let presenter = self.presenter else { return }
                presenter.toggleFavorite(username: user.username)
                let updatedStatus = presenter.isFavorite(username: user.username)
                cell?.updateFavorite(isFavorite: updatedStatus, animated: true)
            }

            return cell
        }
    }()


    private lazy var welcomeImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "searchWelcome"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.85
        imageView.isUserInteractionEnabled = false
        imageView.isHidden = true
        return imageView
    }()

    private lazy var notFoundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "SearchNotFound"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.85
        imageView.isHidden = true
        return imageView
    }()

    private lazy var noInternetImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "NoInternet"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.88
        imageView.isUserInteractionEnabled = false
        imageView.isHidden = true
        return imageView
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Try Again", for: .normal)
        button.tintColor = AppTheme.Colors.accent
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.isHidden = true
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return button
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = AppTheme.Colors.accent
        return indicator
    }()


    private lazy var headerHeightConstraint = headerContainer.heightAnchor.constraint(
        equalToConstant: Layout.headerHeight
    )

    private lazy var messageCenterConstraint = messageLabel.centerYAnchor.constraint(
        equalTo: collectionView.centerYAnchor
    )

    private lazy var messageBelowImageConstraint = messageLabel.topAnchor.constraint(
        equalTo: noInternetImageView.bottomAnchor,
        constant: 8
    )

    private lazy var messageBelowNotFoundConstraint = messageLabel.topAnchor.constraint(
        equalTo: notFoundImageView.bottomAnchor,
        constant: 4
    )


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.Colors.background

        setupHierarchy()
        setupConstraints()
        showInitialState(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func setupHierarchy() {
        [
            headerContainer, searchBar, resultsRow, collectionView,
            welcomeImageView, notFoundImageView, noInternetImageView,
            messageLabel, retryButton, activityIndicator
        ].forEach(view.addSubview)

        [logoImageView, brandLabel, titleLabel, subtitleLabel]
            .forEach(headerContainer.addSubview)

        [resultsLabel, sortButton]
            .forEach(resultsRow.addSubview)
    }

    private func setupConstraints() {
        messageCenterConstraint.isActive = true

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            headerHeightConstraint,

            logoImageView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 4),
            logoImageView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 26),
            logoImageView.heightAnchor.constraint(equalToConstant: 26),

            brandLabel.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor),
            brandLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 10),

            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),

            searchBar.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            searchBar.heightAnchor.constraint(equalToConstant: 54),

            resultsRow.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 6),
            resultsRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultsRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resultsRow.heightAnchor.constraint(equalToConstant: 32),

            resultsLabel.leadingAnchor.constraint(equalTo: resultsRow.leadingAnchor),
            resultsLabel.centerYAnchor.constraint(equalTo: resultsRow.centerYAnchor),

            sortButton.trailingAnchor.constraint(equalTo: resultsRow.trailingAnchor),
            sortButton.centerYAnchor.constraint(equalTo: resultsRow.centerYAnchor),

            collectionView.topAnchor.constraint(equalTo: resultsRow.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            welcomeImageView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            welcomeImageView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: -20),
            welcomeImageView.widthAnchor.constraint(equalToConstant: 280),
            welcomeImageView.heightAnchor.constraint(equalToConstant: 280),

            notFoundImageView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            notFoundImageView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: -65),
            notFoundImageView.widthAnchor.constraint(equalToConstant: 230),
            notFoundImageView.heightAnchor.constraint(equalToConstant: 230),

            noInternetImageView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            noInternetImageView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: -75),
            noInternetImageView.widthAnchor.constraint(equalToConstant: 230),
            noInternetImageView.heightAnchor.constraint(equalToConstant: 230),

            messageLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),

            activityIndicator.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 6, bottom: 7, trailing: 6)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(190)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 14, bottom: 20, trailing: 14)

        return UICollectionViewCompositionalLayout(section: section)
    }


    private func setSearchActive(_ active: Bool) {
        guard isSearchActive != active else { return }
        isSearchActive = active

        headerHeightConstraint.constant = active ? 0 : Layout.headerHeight
        if active { headerContainer.isHidden = false }

        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0.2,
            options: [.curveEaseInOut, .beginFromCurrentState]
        ) {
            self.headerContainer.alpha = active ? 0 : 1
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let self else { return }
            // Respect the latest state when interrupted animations complete.
            self.headerContainer.isHidden = self.isSearchActive
        }

        searchBar.setShowsCancelButton(active, animated: true)
    }


    private func applySort(_ option: SortOption, title: String) {
        sortOption = option
        sortButton.setTitle(title, for: .normal)
        refreshSortedUsers()
    }

    private func refreshSortedUsers() {
        let sorted: [SearchUserViewModel]

        switch sortOption {
        case .defaultOrder:
            sorted = currentUsers
        case .alphabetical:
            sorted = currentUsers.sorted {
                $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending
            }
        case .reverseAlphabetical:
            sorted = currentUsers.sorted {
                $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedDescending
            }
        }

        updateUsers(sorted)
    }

    private func updateUsers(
        _ users: [SearchUserViewModel],
        animatingDifferences: Bool = true
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, SearchUserViewModel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(users, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func hideStatusViews() {
        welcomeImageView.isHidden = true
        noInternetImageView.isHidden = true
        notFoundImageView.isHidden = true
        messageLabel.isHidden = true
        retryButton.isHidden = true
    }

    private func showInitialState(animated: Bool = false) {
        activityIndicator.stopAnimating()
        currentUsers = []
        // Clear the snapshot too, so no stale results stay in the data source.
        updateUsers([], animatingDifferences: false)
        resultsLabel.text = "Find people"
        collectionView.isHidden = true
        hideStatusViews()
        welcomeImageView.isHidden = false

        guard animated else {
            welcomeImageView.alpha = 0.70
            welcomeImageView.transform = .identity
            return
        }

        welcomeImageView.alpha = 0
        welcomeImageView.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)

        UIView.animate(withDuration: 0.5, delay: 0.1, options: [.curveEaseOut]) {
            self.welcomeImageView.alpha = 0.38
            self.welcomeImageView.transform = .identity
        }
    }

    private func setMessagePosition(below image: UIImageView?) {
        messageCenterConstraint.isActive = false
        messageBelowImageConstraint.isActive = false
        messageBelowNotFoundConstraint.isActive = false

        if image === noInternetImageView {
            messageBelowImageConstraint.isActive = true
        } else if image === notFoundImageView {
            messageBelowNotFoundConstraint.isActive = true
        } else {
            messageCenterConstraint.isActive = true
        }
    }

    private func showErrorState(_ message: String, isOffline: Bool) {
        activityIndicator.stopAnimating()
        currentUsers = []
        resultsLabel.text = "0 users"
        updateUsers([])
        collectionView.isHidden = true
        hideStatusViews()

        setMessagePosition(below: isOffline ? noInternetImageView : nil)
        noInternetImageView.isHidden = !isOffline
        messageLabel.text = message
        messageLabel.isHidden = false
        retryButton.isHidden = false
    }


    @objc private func retryTapped() {
        presenter?.searchUsers(query: searchBar.text ?? "")
    }
}


extension SearchViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        hideStatusViews()
        setSearchActive(true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter?.searchUsers(query: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        setSearchActive(false)
        presenter?.searchUsers(query: "")
        showInitialState(animated: true)
    }
}


extension SearchViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = dataSource.itemIdentifier(for: indexPath) else { return }
        searchBar.resignFirstResponder()
        presenter?.didSelectUser(user)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let user = dataSource.itemIdentifier(for: indexPath) else { return }
        presenter?.loadUserDetails(username: user.username)
    }
}


extension SearchViewController: SearchViewInput {

    func displayUsers(_ users: [SearchUserViewModel]) {
        activityIndicator.stopAnimating()
        currentUsers = users
        resultsLabel.text = "\(users.count) users"
        hideStatusViews()
        collectionView.isHidden = false
        refreshSortedUsers()
    }

    func displayLoading() {
        hideStatusViews()
        collectionView.isHidden = true
        activityIndicator.startAnimating()
    }

    func displayEmpty() {
        activityIndicator.stopAnimating()
        currentUsers = []
        updateUsers([])
        hideStatusViews()
        collectionView.isHidden = true

        let isQueryEmpty = searchBar.text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ?? true

        if isQueryEmpty && !isSearchActive {
            showInitialState()
        } else if isQueryEmpty {
            resultsLabel.text = "Find people"
        } else {
            resultsLabel.text = "0 users"
            // A valid response containing no GitHub users is NOT a network error.
            setMessagePosition(below: notFoundImageView)
            notFoundImageView.isHidden = false
            messageLabel.text = "No users found"
            messageLabel.isHidden = false
        }
    }

    func displayError(_ error: SearchDisplayError) {
        switch error {
        case .offline:
            showErrorState("No internet connection", isOffline: true)
        case .general:
            showErrorState("Couldn't load users. Please try again.", isOffline: false)
        }
    }

    func displayUserDetails(username: String, name: String?, bio: String?) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let user = dataSource.itemIdentifier(for: indexPath),
                  user.username == username,
                  let cell = collectionView.cellForItem(at: indexPath) as? SearchUserCell
            else { continue }

            cell.configureDetails(username: username, name: name, bio: bio)
        }
    }
}
