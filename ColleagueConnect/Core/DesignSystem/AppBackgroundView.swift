
import UIKit

final class AppBackgroundView: UIView {

    private let topWave = CAShapeLayer()
    private let topHighlight = CAShapeLayer()
    private let bottomWave = CAShapeLayer()
    private let softGradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        softGradient.frame = bounds
        updateWaves()
    }

    private func setupAppearance() {
        isUserInteractionEnabled = false
        backgroundColor = .white
        clipsToBounds = true

        topWave.fillColor = AppTheme.Colors.backgroundBlush
            .withAlphaComponent(0.55).cgColor

        topHighlight.fillColor = AppTheme.Colors.backgroundLavender
            .withAlphaComponent(0.30).cgColor

        bottomWave.fillColor = AppTheme.Colors.backgroundBlush
            .withAlphaComponent(0.25).cgColor

        softGradient.colors = [
            AppTheme.Colors.backgroundBlush
                .withAlphaComponent(0.14).cgColor,
            UIColor(
                red: 0.992,
                green: 0.978,
                blue: 0.996,
                alpha: 1
            ).cgColor,
            UIColor.white.cgColor,
            UIColor.white.cgColor
        ]

        softGradient.locations = [
            0.0,
            0.20,
            0.43,
            1.0
        ]

        softGradient.startPoint = CGPoint(x: 0, y: 0)
        softGradient.endPoint = CGPoint(x: 0.85, y: 1)

        layer.insertSublayer(softGradient, at: 0)
        layer.addSublayer(topWave)
        layer.addSublayer(topHighlight)
        layer.addSublayer(bottomWave)
    }

    private func updateWaves() {
        let width = bounds.width
        let height = bounds.height

        guard width > 0, height > 0 else { return }

        let upperPath = UIBezierPath()
        upperPath.move(to: CGPoint(x: width * 0.52, y: 0))
        upperPath.addLine(to: CGPoint(x: width, y: 0))
        upperPath.addLine(to: CGPoint(x: width, y: height * 0.19))

        upperPath.addCurve(
            to: CGPoint(x: width * 0.52, y: 0),
            controlPoint1: CGPoint(
                x: width * 0.80,
                y: height * 0.13
            ),
            controlPoint2: CGPoint(
                x: width * 0.76,
                y: height * 0.04
            )
        )

        upperPath.close()
        topWave.path = upperPath.cgPath

        let highlightPath = UIBezierPath()
        highlightPath.move(
            to: CGPoint(x: width * 0.75, y: 0)
        )
        highlightPath.addLine(
            to: CGPoint(x: width, y: 0)
        )
        highlightPath.addLine(
            to: CGPoint(x: width, y: height * 0.11)
        )

        highlightPath.addQuadCurve(
            to: CGPoint(x: width * 0.75, y: 0),
            controlPoint: CGPoint(
                x: width * 0.90,
                y: height * 0.055
            )
        )

        highlightPath.close()
        topHighlight.path = highlightPath.cgPath

        let lowerPath = UIBezierPath()
        lowerPath.move(
            to: CGPoint(x: 0, y: height * 0.81)
        )

        lowerPath.addCurve(
            to: CGPoint(x: width * 0.32, y: height),
            controlPoint1: CGPoint(
                x: width * 0.08,
                y: height * 0.89
            ),
            controlPoint2: CGPoint(
                x: width * 0.22,
                y: height * 0.95
            )
        )

        lowerPath.addLine(to: CGPoint(x: 0, y: height))
        lowerPath.close()
        bottomWave.path = lowerPath.cgPath
    }
}
