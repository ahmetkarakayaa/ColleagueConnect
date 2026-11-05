
import UIKit

enum AppTheme {

    enum Colors {
        static let accent = UIColor(
            red: 0.90,
            green: 0.22,
            blue: 0.84,
            alpha: 1
        )
        static let backgroundBase = UIColor.white

        static let backgroundBlush = UIColor(
            red: 0.918,
            green: 0.714,
            blue: 0.922,
            alpha: 1
        )

        static let backgroundLavender = UIColor(
            red: 0.867,
            green: 0.627,
            blue: 0.922,
            alpha: 1
        )
        static let background = UIColor.systemBackground
        static let surface = UIColor.secondarySystemBackground

        static let primaryText = UIColor.label

        static let secondaryText = UIColor.secondaryLabel

        static let border = UIColor.separator
    }

    enum Radius {
        static let card: CGFloat = 18
        static let button: CGFloat = 12
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
}
