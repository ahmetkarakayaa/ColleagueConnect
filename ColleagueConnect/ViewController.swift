
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Ekranın arka plan rengini belirliyoruz.
        view.backgroundColor = .white

        // Ekranda göstereceğimiz yazıyı oluşturuyoruz.
        let welcomeLabel = UILabel()
        welcomeLabel.text = "Welcome to Colleague Connect"
        welcomeLabel.textColor = .black
        welcomeLabel.textAlignment = .center
        welcomeLabel.font = .systemFont(ofSize: 22, weight: .bold)
        welcomeLabel.numberOfLines = 0

        // Auto Layout kullanacağımızı belirtiyoruz.
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Yazıyı ekrana ekliyoruz.
        view.addSubview(welcomeLabel)

        // Yazıyı ekranın ortasına yerleştiriyoruz.
        NSLayoutConstraint.activate([
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            welcomeLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 20
            ),
            welcomeLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -20
            )
        ])
    }
}

