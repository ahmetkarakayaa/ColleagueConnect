import UIKit

final class FavoritesViewController: UIViewController {

    var presenter: FavoritesViewOutput!

    private let appBackgroundView = AppBackgroundView()

    private enum Section {

        case main

    }

    private var isSearchActive = false

    private weak var clearSearchButton: UIButton?

    private lazy var headerContainer = UIView()

    private lazy var searchBar = UISearchBar()

    private lazy var resultsRow = UIView()

    private var headerHeightConstraint: NSLayoutConstraint!

    private var resultsRowHeightConstraint: NSLayoutConstraint!

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
        button.translatesAutoresizingMaskIntoConstraints = false

        button.setTitle("Sorting", for: .normal)
        button.setTitleColor(AppTheme.Colors.accent, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)

        let symbol = UIImage.SymbolConfiguration(
            pointSize: 13,
            weight: .medium
        )

        button.setImage(
            UIImage(systemName: "arrow.up.arrow.down", withConfiguration: symbol),
            for: .normal
        )

        button.tintColor = AppTheme.Colors.accent
        button.semanticContentAttribute = .forceLeftToRight
        button.backgroundColor = .clear
        button.contentHorizontalAlignment = .trailing

        return button
    }()

    private lazy var activityIndicator = UIActivityIndicatorView(

        style: .large

    )

    private lazy var messageLabel = UILabel()

    private var messageCenterYConstraint: NSLayoutConstraint!

    private lazy var retryButton = UIButton(type: .system)

    private lazy var emptyStateImageView = UIImageView()

    private lazy var noResultsImageView = UIImageView()

    private let emptyTitleLabel: UILabel = {

        let label = UILabel()

        label.text = "No favorites yet"

        label.font = .systemFont(ofSize: 21, weight: .semibold)

        label.textColor = .label

        label.textAlignment = .center

        label.isHidden = true

        return label

    }()

    private let emptySubtitleLabel: UILabel = {

        let label = UILabel()

        label.text = "Profiles you save will appear here."

        label.font = .systemFont(ofSize: 14)

        label.textColor = .secondaryLabel

        label.textAlignment = .center

        label.numberOfLines = 0

        label.isHidden = true

        return label

    }()

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
        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.tintColor = AppTheme.Colors.accent

        setupUI()

        setupSearchBar()


        configureSearchClearButton()

        setupCollectionView()

        setupDataSource()

        setupSortMenu()

        presenter.viewDidLoad()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let button = clearSearchButton {
            searchBar.bringSubviewToFront(button)
        }
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = AppTheme.Colors.accent

        navigationController?.setNavigationBarHidden(

            true,

            animated: animated

        )

        presenter.viewWillAppear()

    }

    override func viewWillDisappear(_ animated: Bool) {

        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(

            false,

            animated: animated

        )
        navigationController?.navigationBar.tintColor = AppTheme.Colors.accent

    }

    private func setupUI() {

        view.backgroundColor = AppTheme.Colors.background

        resultsLabel.isHidden = true

        subtitleLabel.isHidden = true

        appBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(appBackgroundView)

        activityIndicator.hidesWhenStopped = true

        activityIndicator.color = AppTheme.Colors.accent

        messageLabel.textAlignment = .center

        messageLabel.numberOfLines = 0

        messageLabel.textColor = AppTheme.Colors.secondaryText

        messageLabel.font = .systemFont(ofSize: 15)

        noResultsImageView.image = UIImage(named: "SearchNotFound")

        noResultsImageView.contentMode = .scaleAspectFit

        noResultsImageView.isHidden = true

        emptyStateImageView.image = UIImage(named: "favorites_empty_state")

        emptyStateImageView.alpha = 1

        emptyStateImageView.contentMode = .scaleAspectFit

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

            noResultsImageView,

            emptyTitleLabel,

            emptySubtitleLabel,

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

            equalToConstant: 105

        )

        resultsRowHeightConstraint = resultsRow.heightAnchor.constraint(equalToConstant: 32)

        messageCenterYConstraint = messageLabel.centerYAnchor.constraint(

            equalTo: collectionView.centerYAnchor

        )

        NSLayoutConstraint.activate([

            appBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),

            appBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            appBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            appBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateImageView.centerXAnchor.constraint(

                equalTo: collectionView.centerXAnchor

            ),

            emptyStateImageView.centerYAnchor.constraint(

                equalTo: collectionView.centerYAnchor,

                constant: -75

            ),

            emptyStateImageView.widthAnchor.constraint(equalToConstant: 300),

            emptyStateImageView.heightAnchor.constraint(equalToConstant: 300),

            noResultsImageView.centerXAnchor.constraint(

                equalTo: collectionView.centerXAnchor

            ),

            noResultsImageView.centerYAnchor.constraint(

                equalTo: collectionView.centerYAnchor,

                constant: -65

            ),

            noResultsImageView.widthAnchor.constraint(equalToConstant: 230),

            noResultsImageView.heightAnchor.constraint(equalToConstant: 230),

            emptyTitleLabel.topAnchor.constraint(

                equalTo: emptyStateImageView.bottomAnchor,

                constant: -35

            ),

            emptyTitleLabel.centerXAnchor.constraint(

                equalTo: collectionView.centerXAnchor

            ),

            emptySubtitleLabel.topAnchor.constraint(

                equalTo: emptyTitleLabel.bottomAnchor,

                constant: 8

            ),

            emptySubtitleLabel.centerXAnchor.constraint(

                equalTo: collectionView.centerXAnchor

            ),

            emptySubtitleLabel.leadingAnchor.constraint(

                greaterThanOrEqualTo: view.leadingAnchor,

                constant: 24

            ),

            emptySubtitleLabel.trailingAnchor.constraint(

                lessThanOrEqualTo: view.trailingAnchor,

                constant: -24

            ),

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
                equalTo: searchBar.searchTextField.trailingAnchor
            ),

            sortButton.centerYAnchor.constraint(

                equalTo: resultsRow.centerYAnchor

            ),
            sortButton.widthAnchor.constraint(equalToConstant: 110),
            sortButton.heightAnchor.constraint(equalToConstant: 40),

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

            messageCenterYConstraint,

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

    private func setResultsRowVisible(_ visible: Bool) {

        resultsRowHeightConstraint.constant = visible ? 32 : 0

        resultsRow.isHidden = !visible

    }

    private func setSearchActive(_ active: Bool) {

        guard isSearchActive != active else { return }

        isSearchActive = active

        if active {

            setResultsRowVisible(false)

        }

        headerHeightConstraint.constant = active ? 0 : 105

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

        searchBar.setShowsCancelButton(false, animated: false)
        clearSearchButton?.alpha = active ? 1 : 0

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

    private func configureSearchClearButton() {
        let field = searchBar.searchTextField
        field.clearButtonMode = .never
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 32))
        field.rightViewMode = .always

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let symbol = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: symbol), for: .normal)
        button.tintColor = AppTheme.Colors.accent
        button.accessibilityLabel = "Close search"
        button.alpha = 0
        button.addTarget(self, action: #selector(closeSearchTapped), for: .touchUpInside)
        searchBar.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: field.trailingAnchor, constant: -7),
            button.centerYAnchor.constraint(equalTo: field.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        searchBar.bringSubviewToFront(button)
        clearSearchButton = button
    }

    private func setupCollectionView() {

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        

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

                self?.presenter.sortFavorites(by: .newest)



            },

            UIAction(title: "Oldest added") { [weak self] _ in

                self?.presenter.sortFavorites(by: .oldest)

        

            },

            UIAction(title: "Username A–Z") { [weak self] _ in

                self?.presenter.sortFavorites(by: .alphabetical)

      

            },

            UIAction(title: "Username Z–A") { [weak self] _ in

                self?.presenter.sortFavorites(by: .reverseAlphabetical)

      

            }

        ])

        sortButton.showsMenuAsPrimaryAction = true

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

    @objc private func closeSearchTapped() {
        searchBar.text = ""
        clearSearchButton?.alpha = 0
        searchBarCancelButtonClicked(searchBar)
    }

    @objc private func retryTapped() {

        presenter.retryFavorites()

    }

}

extension FavoritesViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

        emptyStateImageView.isHidden = true

        emptyTitleLabel.isHidden = true

        emptySubtitleLabel.isHidden = true

        setSearchActive(true)
        clearSearchButton?.alpha = 1

        setResultsRowVisible(false)

    }

    func searchBar(

        _ searchBar: UISearchBar,

        textDidChange searchText: String

    ) {

        clearSearchButton?.alpha = 1

        presenter.filterFavorites(query: searchText)

    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {

        presenter.filterFavorites(query: searchBar.text ?? "")

    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        searchBar.resignFirstResponder()

    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {

        searchBar.text = ""

        searchBar.resignFirstResponder()

        setSearchActive(false)

        presenter.filterFavorites(query: "")

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

        noResultsImageView.isHidden = true

        setResultsRowVisible(

            !users.isEmpty && !searchBar.searchTextField.isFirstResponder

        )

        emptyTitleLabel.isHidden = true

        emptySubtitleLabel.isHidden = true

        emptyStateImageView.isHidden = true

        activityIndicator.stopAnimating()

        resultsLabel.text = "\(users.count) saved"

        messageLabel.isHidden = true

        retryButton.isHidden = true

        collectionView.isHidden = false

        updateUsers(users)    }

    func displayLoading() {

        noResultsImageView.isHidden = true

        setResultsRowVisible(false)

        emptyTitleLabel.isHidden = true

        emptySubtitleLabel.isHidden = true

        messageLabel.isHidden = true

        retryButton.isHidden = true

        emptyStateImageView.isHidden = true

        collectionView.isHidden = true

        activityIndicator.startAnimating()

    }

    func displayEmpty() {

        noResultsImageView.isHidden = true

        setResultsRowVisible(false)

        activityIndicator.stopAnimating()

        updateUsers([])

        resultsLabel.text = "0 saved"

        collectionView.isHidden = true

        retryButton.isHidden = true

        messageLabel.isHidden = true

        let showEmptyState = !searchBar.searchTextField.isFirstResponder

        emptyStateImageView.isHidden = !showEmptyState

        emptyTitleLabel.isHidden = !showEmptyState

        emptySubtitleLabel.isHidden = !showEmptyState

    }

    func displayNoResults() {

        noResultsImageView.isHidden = true
        messageLabel.isHidden = true
        messageCenterYConstraint.constant = 35

        emptyStateImageView.isHidden = true

        emptyTitleLabel.isHidden = true

        emptySubtitleLabel.isHidden = true

        setResultsRowVisible(false)

        activityIndicator.stopAnimating()

        updateUsers([])

        resultsLabel.text = "0 matches"

        collectionView.isHidden = true

        retryButton.isHidden = true

        messageLabel.text = "No matching favorites"
        view.layoutIfNeeded()
        noResultsImageView.isHidden = false
        messageLabel.isHidden = false

    }

    func displayError(_ message: String) {

        messageCenterYConstraint.constant = 0

        noResultsImageView.isHidden = true

        setResultsRowVisible(false)

        emptyTitleLabel.isHidden = true

        emptySubtitleLabel.isHidden = true

        activityIndicator.stopAnimating()

        updateUsers([])

        collectionView.isHidden = true

        messageLabel.isHidden = false

        retryButton.isHidden = false

        emptyStateImageView.isHidden = true

        messageLabel.text = message

    }

}
