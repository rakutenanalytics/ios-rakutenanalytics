import UIKit
import RAnalytics
import WebKit
#if canImport(RSDKUtilsMain)
import RSDKUtilsMain // for RAnalyticsSampleSPM
#else
import RSDKUtils
#endif

enum GlobalConstants {
    static let kLocationTracking = "Location_Tracking"
    static let kIDFATracking = "IDFA_Tracking"
    static let kRATAccountID = "RAT_Account_ID"
    static let kRATAppID = "RAT_App_ID"
    static let kRATUrlScheme = "Open URL Scheme"
    static let kRATUniversalLink = "Open Universal Link"
    static let enableAppUserAgent = "Enable App user agent"
    static let showWebViewUserAgent = "Show WKWebView's user agent"
}

enum TableViewCellType: Int, CaseIterable {
    case location, idfa, accountID, appID, urlScheme, universalLink, enableAppUserAgent, showWebViewUserAgent

    var cellIdentifier: String {
        switch self {
        case .location, .idfa, .enableAppUserAgent:
            return "SwitchTableViewCell"
        case .accountID, .appID:
            return "TextFieldTableViewCell"
        case .urlScheme, .universalLink, .showWebViewUserAgent:
            return "BaseTableViewCell"
        }
    }

    var title: String {
        switch self {
        case .location:
            return GlobalConstants.kLocationTracking
        case .idfa:
            return GlobalConstants.kIDFATracking
        case .accountID:
            return GlobalConstants.kRATAccountID
        case .appID:
            return GlobalConstants.kRATAppID
        case .urlScheme:
            return GlobalConstants.kRATUrlScheme
        case .universalLink:
            return GlobalConstants.kRATUniversalLink
        case .enableAppUserAgent:
            return GlobalConstants.enableAppUserAgent
        case .showWebViewUserAgent:
            return GlobalConstants.showWebViewUserAgent
        }
    }
}

class TableViewController: UITableViewController, BaseCellDelegate {

    private var accountId: String = (Bundle.main.object(forInfoDictionaryKey: "RATAccountIdentifier") as? NSNumber)?.stringValue ?? ""
    private var applicationId: String = (Bundle.main.object(forInfoDictionaryKey: "RATAppIdentifier") as? NSNumber)?.stringValue ?? ""
    private let link = "campaignCode"
    private let component =  "news"
    private let customParameters: [String: String] = {
        var customParameters = [String: String]()
        customParameters["custom_param1"] = "japan"
        customParameters["custom_param2"] = "tokyo"
        customParameters["ref_custom_param1"] = "italy"
        customParameters["ref_custom_param2"] = "rome"
        return customParameters
    }()
    private let webViewURL: URL! = URL(string: "https://www.rakuten.co.jp")
    private var webView: WKWebView!

    enum Constants {
        static let domain = "check.rat.rakuten.co.jp"
    }

    @IBOutlet weak var spoolButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        webView = WKWebView(frame: view.bounds)
        navigationItem.title = Bundle.main.infoDictionary?["CFBundleName"] as? String
    }

    func update(_ dict: [String: Any]) {
        if let value = dict[GlobalConstants.kLocationTracking],
           let flag = value as? Bool {
            AnalyticsManager.shared().shouldTrackLastKnownLocation = flag
        }

        if let value = dict[GlobalConstants.kIDFATracking],
           let flag = value as? Bool {
            AnalyticsManager.shared().shouldTrackAdvertisingIdentifier = flag
        }

        if let value = dict[GlobalConstants.enableAppUserAgent],
           let enabled = value as? Bool {
            webView.enableAppUserAgent(enabled)
        }

        if let accountIdString = dict[GlobalConstants.kRATAccountID] as? String {
            self.accountId = accountIdString
        }

        if let appIdString = dict[GlobalConstants.kRATAppID] as? String {
            self.applicationId = appIdString
        }
    }

    @IBAction func spool(_ sender: Any) {
        RAnalyticsRATTracker.shared().event(withEventType: "SampleEvent",
                                            parameters: ["foo": "bar",
                                                         "acc": accountId,
                                                         "aid": applicationId]).track()

        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
            _ = cookies.map { (cookie) in
                print(cookie)
            }
        }
        // For quick testing of _RAnalyticsCookieInjector load a zero-frame webview
        WKWebView(frame: .zero).load(URLRequest(url: URL(string: "https://corp.rakuten.co.jp")!))
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableViewCellType.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellType = TableViewCellType(rawValue: indexPath.row),
              let cell = tableView.dequeueReusableCell(withIdentifier: cellType.cellIdentifier, for: indexPath) as? BaseTableViewCell else {
            return UITableViewCell()
        }

        if cell is SwitchTableViewCell && cellType == .enableAppUserAgent {
            (cell as? SwitchTableViewCell)?.usingSwitch.isOn = AnalyticsManager.shared().isWebViewAppUserAgentEnabledAtBuildtime
        }

        cell.delegate = self
        cell.title = cellType.title
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cellType = TableViewCellType(rawValue: indexPath.row) else {
            return
        }

        guard let model = ReferralAppModel(accountIdentifier: Int64(accountId) ?? 0,
                                           applicationIdentifier: Int64(applicationId) ?? 0,
                                           link: link,
                                           component: component,
                                           customParameters: customParameters) else {
            return
        }

        switch cellType {
        case .urlScheme:
            guard let url = model.urlScheme(appScheme: "demoapp"),
                  UIApplication.shared.canOpenURL(url) else {
                UIAlertController.showError("Could not open URL Scheme", from: self)
                return
            }
            UIApplication.shared.open(url, options: [:])

        case .universalLink:
            guard let url = model.universalLink(domain: Constants.domain),
                  UIApplication.shared.canOpenURL(url) else {
                UIAlertController.showError("Could not open Universal Link", from: self)
                return
            }
            UIApplication.shared.open(url, options: [:])

        case .showWebViewUserAgent:
            guard let userAgent = webView.rCurrentUserAgent else {
                return
            }

            webView.load(URLRequest(url: webViewURL))

            let alertController = UIAlertController(title: "User Agent",
                                                    message: userAgent,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Close", style: .cancel))
            alertController.addAction(UIAlertAction(title: "Copy", style: .default, handler: { _ in
                UIPasteboard.general.string = userAgent
            }))
            present(alertController, animated: true)

        default: ()
        }
    }
}

// MARK: - Alert

private extension UIAlertController {
    static func showError(_ message: String, from viewController: UIViewController) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        viewController.present(alertController, animated: true)
    }
}
