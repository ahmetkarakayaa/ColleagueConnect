
import UIKit

final class FavoritesViewController: UIViewController {

    var presenter: FavoritesViewOutput!

    private enum Section {
        case main
    }

    private let searchController = UISearchController(
        searchResultsController: nil
    )

    private let activityIndicator = UIActivityIndicatorView(
        style: .large
    )

    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

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
        setupCollectionView()
        setupDataSource()
        setupSearchController()

        presenter.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }

    private func setupUI() {
        title = "Favorites"
        view.backgroundColor = AppTheme.Colors.background

        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = AppTheme.Colors.secondaryText
        messageLabel.font = .systemFont(ofSize: 15)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = AppTheme.Colors.accent

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

        [
            collectionView,
            messageLabel,
            activityIndicator,
            retryButton
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            collectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            collectionView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),

            messageLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            messageLabel.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
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
                equalTo: view.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
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
            top: 6,
            leading: 6,
            bottom: 6,
            trailing: 6
        )

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(184)
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item, item]
        )

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: 12,
            bottom: 20,
            trailing: 12
        )

        return UICollectionViewCompositionalLayout(
            section: section
        )
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .clear

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
                withReuseIdentifier:
                    SearchUserCell.reuseIdentifier,
                for: indexPath
            ) as? SearchUserCell else {
                return UICollectionViewCell()
            }

            cell.configureFavorite(with: user)

            cell.onFavoriteTapped = { [weak self] in
                self?.presenter.removeFavorite(
                    username: user.username
                )
            }

            return cell
        }
    }

    
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter favorites"

        let searchField = searchController.searchBar.searchTextField

        searchField.backgroundColor = AppTheme.Colors.background
        searchField.borderStyle = .none
        searchField.background = UIImage()
        searchField.layer.cornerRadius = 14
        searchField.layer.borderWidth = 1.5
        searchField.layer.borderColor = AppTheme.Colors.accent.cgColor
        searchField.clipsToBounds = true

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.rightBarButtonItem = nil

        definesPresentationContext = true
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

extension FavoritesViewController: UISearchResultsUpdating {

    func updateSearchResults(
        for searchController: UISearchController
    ) {
        presenter.filterFavorites(
            query: searchController.searchBar.text ?? ""
        )
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

        presenter.didSelectUser(user)
    }
}

extension FavoritesViewController: FavoritesViewInput {

    func displayFavorites(_ users: [FavoriteUserViewModel]) {
        activityIndicator.stopAnimating()

        messageLabel.isHidden = true
        retryButton.isHidden = true
        collectionView.isHidden = false

        updateUsers(users)
    }

    func displayLoading() {
        messageLabel.isHidden = true
        retryButton.isHidden = true
        collectionView.isHidden = true

        activityIndicator.startAnimating()
    }

    func displayEmpty() {
        activityIndicator.stopAnimating()

        updateUsers([])

        collectionView.isHidden = true
        retryButton.isHidden = true
        messageLabel.isHidden = false

        messageLabel.text = "No favorites yet"
    }

    func displayError(_ message: String) {
        activityIndicator.stopAnimating()

        updateUsers([])

        collectionView.isHidden = true
        messageLabel.isHidden = false
        retryButton.isHidden = false

        messageLabel.text = message
    }
}
