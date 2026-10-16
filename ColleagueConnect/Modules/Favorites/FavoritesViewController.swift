
import UIKit
final class FavoritesViewController: UIViewController {
    var presenter: FavoritesViewOutput!
    private enum Section {
        case main
    }
    private enum SortOption {
        case newest
        case oldest
        case alphabetical
        case reverseAlphabetical
    }
    private var sortOption: SortOption = .newest
    private var currentUsers: [FavoriteUserViewModel] = []
    private var isSearchActive = false
    private lazy var headerContainer = UIView()
    private lazy var searchBar = UISearchBar()
    private lazy var resultsRow = UIView()
    private var headerHeightConstraint: NSLayoutConstraint!
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(systemName: "person.2.fill")
        )
        imageView.tintColor = AppTheme.Colors.accent
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private lazy var brandLabel: UILabel = {
        let label = UILabel()
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
        label.text = "Favorites"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .label
        return label
    }()
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Your saved profiles in one place."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    private lazy var resultsLabel: UILabel = {
        let label = UILabel()
        label.text = "Saved profiles"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()
    private lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sort: Recent", for: .normal)
        button.titleLabel?.font = .systemFont(
            ofSize: 12,
            weight: .medium
        )
        button.tintColor = .secondaryLabel
        return button
    }()
    private lazy var activityIndicator = UIActivityIndicatorView(
        style: .large
    )
    private lazy var messageLabel = UILabel()
    private lazy var retryButton = UIButton(type: .system)
    private lazy var emptyStateImageView = UIImageView()
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    )
    private var dataSource:
        UICollectionViewDiffableDataSource<
            Section,
            FavoriteUserViewModel
        >!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchBar()
        setupCollectionView()
        setupDataSource()
        setupSortMenu()
        presenter.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(
            true,
            animated: false
        )
        presenter.viewWillAppear()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(
            false,
            animated: false
        )
    }
    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.background
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = AppTheme.Colors.accent
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = AppTheme.Colors.secondaryText
        messageLabel.font = .systemFont(ofSize: 15)
        emptyStateImageView.image = UIImage(named: "favoritesEmptyState")
        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateImageView.alpha = 0.70
        emptyStateImageView.isHidden = true
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
        retryButton.isHidden = true
        [
            headerContainer,
            searchBar,
            resultsRow,
            collectionView,
            emptyStateImageView,
            messageLabel,
            activityIndicator,
            retryButton
            ].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview($0)
            }
        [
            logoImageView,
            brandLabel,
            titleLabel,
            subtitleLabel
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerContainer.addSubview($0)
        }
        [resultsLabel, sortButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            resultsRow.addSubview($0)
        }
        headerContainer.clipsToBounds = true
        headerHeightConstraint = headerContainer.heightAnchor.constraint(
            equalToConstant: 126
        )
        NSLayoutConstraint.activate([
            emptyStateImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 280),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 280),
            headerContainer.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 6
            ),
            headerContainer.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            headerContainer.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),
            headerHeightConstraint,
            logoImageView.topAnchor.constraint(
                equalTo: headerContainer.topAnchor,
                constant: 4
            ),
            logoImageView.leadingAnchor.constraint(
                equalTo: headerContainer.leadingAnchor
            ),
            logoImageView.widthAnchor.constraint(
                equalToConstant: 26
            ),
            logoImageView.heightAnchor.constraint(
                equalToConstant: 26
            ),
            brandLabel.centerYAnchor.constraint(
                equalTo: logoImageView.centerYAnchor
            ),
            brandLabel.leadingAnchor.constraint(
                equalTo: logoImageView.trailingAnchor,
                constant: 10
            ),
            titleLabel.topAnchor.constraint(
                equalTo: logoImageView.bottomAnchor,
                constant: 24
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: headerContainer.leadingAnchor
            ),
            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 4
            ),
            subtitleLabel.leadingAnchor.constraint(
                equalTo: headerContainer.leadingAnchor
            ),
            subtitleLabel.trailingAnchor.constraint(
                equalTo: headerContainer.trailingAnchor
            ),
            searchBar.topAnchor.constraint(
                equalTo: headerContainer.bottomAnchor
            ),
            searchBar.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 14
            ),
            searchBar.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -14
            ),
            searchBar.heightAnchor.constraint(
                equalToConstant: 54
            ),
            resultsRow.topAnchor.constraint(
                equalTo: searchBar.bottomAnchor,
                constant: 6
            ),
            resultsRow.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            resultsRow.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),
            resultsRow.heightAnchor.constraint(
                equalToConstant: 32
            ),
            resultsLabel.leadingAnchor.constraint(
                equalTo: resultsRow.leadingAnchor
            ),
            resultsLabel.centerYAnchor.constraint(
                equalTo: resultsRow.centerYAnchor
            ),
            sortButton.trailingAnchor.constraint(
                equalTo: resultsRow.trailingAnchor
            ),
            sortButton.centerYAnchor.constraint(
                equalTo: resultsRow.centerYAnchor
            ),
            collectionView.topAnchor.constraint(
                equalTo: resultsRow.bottomAnchor,
                constant: 4
            ),
            collectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            collectionView.bottomAnchor.constraint(
                equalTo: view.keyboardLayoutGuide.topAnchor
            ),
            messageLabel.centerXAnchor.constraint(
                equalTo: collectionView.centerXAnchor
            ),
            messageLabel.centerYAnchor.constraint(
                equalTo: collectionView.centerYAnchor
            ),
            messageLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 30
            ),
            messageLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -30
            ),
            activityIndicator.centerXAnchor.constraint(
                equalTo: collectionView.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: collectionView.centerYAnchor
            ),
            retryButton.topAnchor.constraint(
                equalTo: messageLabel.bottomAnchor,
                constant: 16
            ),
            retryButton.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            )
        ])
    }
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search favorites"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()
        let field = searchBar.searchTextField
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
    }
    private func setSearchActive(_ active: Bool) {
        guard isSearchActive != active else { return }
        isSearchActive = active
        headerHeightConstraint.constant = active ? 0 : 126
        if active {
            headerContainer.isHidden = false
        }
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.88,
            initialSpringVelocity: 0.2,
            options: [.curveEaseInOut, .beginFromCurrentState]
        ) {
            self.headerContainer.alpha = active ? 0 : 1
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.headerContainer.isHidden = self.isSearchActive
        }
        searchBar.setShowsCancelButton(
            active,
            animated: true
        )
    }
    private func createLayout()
        -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(
            layoutSize: itemSize
        )
        item.contentInsets = NSDirectionalEdgeInsets(
            top: 7,
            leading: 6,
            bottom: 7,
            trailing: 6
        )
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(190)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item, item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 5,
            leading: 14,
            bottom: 20,
            trailing: 14
        )
        return UICollectionViewCompositionalLayout(
            section: section
        )
    }
    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .onDrag
        collectionView.register(
            SearchUserCell.self,
            forCellWithReuseIdentifier:
                SearchUserCell.reuseIdentifier
        )
        collectionView.delegate = self
    }
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<
            Section,
            FavoriteUserViewModel
        >(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, user in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SearchUserCell.reuseIdentifier,
                for: indexPath
            ) as? SearchUserCell else {
                return UICollectionViewCell()
            }
            cell.configureFavorite(with: user)
            cell.configureDetails(
                username: user.username,
                name: user.name,
                bio: user.bio
            )
            cell.onFavoriteTapped = { [weak self] in
                self?.presenter.removeFavorite(
                    username: user.username
                )
            }
            return cell
        }
    }
    private func setupSortMenu() {
        sortButton.menu = UIMenu(children: [
            UIAction(title: "Newest added") { [weak self] _ in
                self?.sortOption = .newest
                self?.sortButton.setTitle(
                    "Sort: Recent",
                    for: .normal
                )
                self?.refreshSortedUsers()
            },
            UIAction(title: "Oldest added") { [weak self] _ in
                self?.sortOption = .oldest
                self?.sortButton.setTitle(
                    "Sort: Oldest",
                    for: .normal
                )
                self?.refreshSortedUsers()
            },
            UIAction(title: "Username A–Z") { [weak self] _ in
                self?.sortOption = .alphabetical
                self?.sortButton.setTitle(
                    "Sort: A–Z",
                    for: .normal
                )
                self?.refreshSortedUsers()
            },
            UIAction(title: "Username Z–A") { [weak self] _ in
                self?.sortOption = .reverseAlphabetical
                self?.sortButton.setTitle(
                    "Sort: Z–A",
                    for: .normal
                )
                self?.refreshSortedUsers()
            }
        ])
        sortButton.showsMenuAsPrimaryAction = true
    }
    private func refreshSortedUsers() {
        let sorted: [FavoriteUserViewModel]
        switch sortOption {
        case .newest:
            sorted = currentUsers
        case .oldest:
            sorted = Array(currentUsers.reversed())
        case .alphabetical:
            sorted = currentUsers.sorted {
                $0.username.localizedCaseInsensitiveCompare(
                    $1.username
                ) == .orderedAscending
            }
        case .reverseAlphabetical:
            sorted = currentUsers.sorted {
                $0.username.localizedCaseInsensitiveCompare(
                    $1.username
                ) == .orderedDescending
            }
        }
        updateUsers(sorted)
    }
    private func updateUsers(_ users: [FavoriteUserViewModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<
            Section,
            FavoriteUserViewModel
        >()
        snapshot.appendSections([.main])
        snapshot.appendItems(users, toSection: .main)
        dataSource.apply(
            snapshot,
            animatingDifferences: true
        )
    }
    @objc private func retryTapped() {
        presenter.viewWillAppear()
    }
}
extension FavoritesViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        setSearchActive(true)
    }
    func searchBar(
        _ searchBar: UISearchBar,
        textDidChange searchText: String
    ) {
        presenter.filterFavorites(query: searchText)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        presenter.filterFavorites(query: "")
        setSearchActive(false)
    }
}
extension FavoritesViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let user = dataSource.itemIdentifier(
            for: indexPath
        ) else {
            return
        }
        searchBar.resignFirstResponder()
        presenter.didSelectUser(user)
    }
}
extension FavoritesViewController: FavoritesViewInput {
    func displayFavorites(_ users: [FavoriteUserViewModel]) {
        emptyStateImageView.isHidden = true
        activityIndicator.stopAnimating()
        currentUsers = users
        resultsLabel.text = "\(users.count) saved"
        messageLabel.isHidden = true
        retryButton.isHidden = true
        collectionView.isHidden = false
        refreshSortedUsers()
    }
    func displayLoading() {
        messageLabel.isHidden = true
        retryButton.isHidden = true
        emptyStateImageView.isHidden = true
        collectionView.isHidden = true
        activityIndicator.startAnimating()
    }
    func displayEmpty() {
        activityIndicator.stopAnimating()
        currentUsers = []
        updateUsers([])
        resultsLabel.text = "0 saved"
        collectionView.isHidden = true
        retryButton.isHidden = true
        messageLabel.isHidden = true
        emptyStateImageView.isHidden = false
    }
    func displayNoResults() {
        activityIndicator.stopAnimating()
        currentUsers = []
        updateUsers([])
        resultsLabel.text = "0 matches"
        collectionView.isHidden = true
        emptyStateImageView.isHidden = true
        retryButton.isHidden = true
        messageLabel.text = "No favorites found"
        messageLabel.isHidden = false
    }
    func displayError(_ message: String) {
        activityIndicator.stopAnimating()
        currentUsers = []
        updateUsers([])
        collectionView.isHidden = true
        messageLabel.isHidden = false
        retryButton.isHidden = false
        emptyStateImageView.isHidden = true
        messageLabel.text = message
    }
}
