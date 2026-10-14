
import UIKit

final class SearchViewController: UIViewController {

    var presenter: SearchViewOutput!

    private enum Section: Hashable {
        case main
    }

    private let searchController = UISearchController(
        searchResultsController: nil
    )

    private let activityIndicator = UIActivityIndicatorView(
        style: .large
    )

    private let messageLabel = UILabel()

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    )

    private var dataSource:
        UICollectionViewDiffableDataSource<
            Section,
            SearchUserViewModel
        >!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupCollectionView()
        setupDataSource()
        setupSearchController()
    }

    private func setupUI() {
        title = "Search"
        view.backgroundColor = AppTheme.Colors.background

        messageLabel.text = "Search for GitHub users"
        messageLabel.textAlignment = .center
        messageLabel.textColor = AppTheme.Colors.secondaryText
        messageLabel.numberOfLines = 0

        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = AppTheme.Colors.accent

        [
            collectionView,
            messageLabel,
            activityIndicator
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
                equalTo: view.bottomAnchor
            ),

            messageLabel.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            messageLabel.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
            ),
            messageLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 24
            ),
            messageLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -24
            ),

            activityIndicator.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
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

        let section = NSCollectionLayoutSection(
            group: group
        )

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
            SearchUserViewModel
        >(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, user in

            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SearchUserCell.reuseIdentifier,
                for: indexPath
            ) as? SearchUserCell else {
                return UICollectionViewCell()
            }

            guard let self = self else {
                return cell
            }

            let isFavorite = self.presenter.isFavorite(
                username: user.username
            )

            cell.configure(
                with: user,
                isFavorite: isFavorite
            )

            cell.onFavoriteTapped = { [weak self, weak cell] in
                guard let self = self else { return }

                self.presenter.toggleFavorite(
                    username: user.username
                )

                let updatedStatus = self.presenter.isFavorite(
                    username: user.username
                )

                cell?.updateFavorite(
                    isFavorite: updatedStatus,
                    animated: true
                )
            }

            return cell
        }
    }



    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search users"

        let searchBar = searchController.searchBar
        let searchField = searchBar.searchTextField

        
        searchField.backgroundColor = .systemBackground
        searchField.borderStyle = .none
        searchField.background = UIImage()

        
        searchField.layer.cornerRadius = 14
        searchField.layer.borderWidth = 1.5
        searchField.layer.borderColor = AppTheme.Colors.accent.cgColor
        searchField.layer.masksToBounds = true

        searchField.textColor = AppTheme.Colors.primaryText
        searchField.tintColor = AppTheme.Colors.accent

        
        searchField.leftView?.tintColor = AppTheme.Colors.accent

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func updateUsers(
        _ users: [SearchUserViewModel]
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<
            Section,
            SearchUserViewModel
        >()

        snapshot.appendSections([.main])
        snapshot.appendItems(users, toSection: .main)

        dataSource.apply(
            snapshot,
            animatingDifferences: true
        )
    }
}

extension SearchViewController: UISearchResultsUpdating {

    func updateSearchResults(
        for searchController: UISearchController
    ) {
        let query = searchController.searchBar.text ?? ""
        presenter.searchUsers(query: query)
    }
}

extension SearchViewController: UICollectionViewDelegate {

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

extension SearchViewController: SearchViewInput {

    func displayUsers(_ users: [SearchUserViewModel]) {
        activityIndicator.stopAnimating()

        messageLabel.isHidden = true
        collectionView.isHidden = false

        updateUsers(users)
    }

    func displayLoading() {
        messageLabel.isHidden = true
        collectionView.isHidden = true

        activityIndicator.startAnimating()
    }

    func displayEmpty() {
        activityIndicator.stopAnimating()

        updateUsers([])

        collectionView.isHidden = true
        messageLabel.isHidden = false
        messageLabel.text = "No users found"
    }

    func displayError(_ message: String) {
        activityIndicator.stopAnimating()

        updateUsers([])

        collectionView.isHidden = true
        messageLabel.isHidden = false
        messageLabel.text = message
    }
}
