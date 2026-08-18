import UIKit

class ViewController: UIViewController {

    private let refTitleLabel = UILabel()
    private let refValueLabel = UILabel()
    private let pathTitleLabel = UILabel()
    private let pathValueLabel = UILabel()
    private let urlTitleLabel = UILabel()
    private let urlValueLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Bundle.main.infoDictionary?["CFBundleName"] as? String
        setupLabels()
        refreshContent()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshContent),
                                               name: IncomingDeepLinkStore.didReceiveNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupLabels() {
        refTitleLabel.text = "ref"
        pathTitleLabel.text = "URL Scheme Path Component"
        urlTitleLabel.text = "Full URL"

        [refTitleLabel, pathTitleLabel, urlTitleLabel].forEach {
            $0.font = .boldSystemFont(ofSize: 15)
            $0.numberOfLines = 0
        }

        [refValueLabel, pathValueLabel, urlValueLabel].forEach {
            $0.font = .systemFont(ofSize: 15)
            $0.numberOfLines = 0
            $0.textColor = .secondaryLabel
        }

        let stack = UIStackView(arrangedSubviews: [
            refTitleLabel, refValueLabel,
            makeSpacer(),
            pathTitleLabel, pathValueLabel,
            makeSpacer(),
            urlTitleLabel, urlValueLabel
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
    }

    private func makeSpacer() -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        return spacer
    }

    @objc private func refreshContent() {
        guard IncomingDeepLinkStore.lastReceivedURL != nil else {
            refValueLabel.text = "No deep link received yet"
            pathValueLabel.text = "(none)"
            urlValueLabel.text = "—"
            return
        }

        refValueLabel.text = IncomingDeepLinkStore.ref ?? "(missing)"
        pathValueLabel.text = IncomingDeepLinkStore.pathComponent ?? "(none)"
        urlValueLabel.text = IncomingDeepLinkStore.lastReceivedURL?.absoluteString ?? "—"
    }
}
