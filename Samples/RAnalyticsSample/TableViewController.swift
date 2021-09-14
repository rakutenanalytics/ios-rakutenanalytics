import UIKit
import RAnalytics
import WebKit

enum GlobalConstants {
    static let kLocationTracking = "Location_Tracking"
    static let kIDFATracking = "IDFA_Tracking"
    static let kRATAccountID = "RAT_Account_ID"
    static let kRATAppID = "RAT_App_ID"
    static let kRATUrlScheme = "Open URL Scheme"
    static let kRATUniversalLink = "Open Universal Link"
}

enum TableViewCellType: Int, CaseIterable {
    case location, idfa, accountID, appID, urlScheme, universalLink

    var cellIdentifier: String {
        switch self {
        case .location, .idfa:
            return "SwitchTableViewCell"
        case .accountID, .appID:
            return "TextFieldTableViewCell"
        case .urlScheme, .universalLink:
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
        }
    }
}

class TableViewController: UITableViewController, BaseCellDelegate {

    var accountId: Int64 = 0
    var serviceId: Int64 = 0

    enum Constants {
        static let bundleIdentifier = Bundle.main.bundleIdentifier!

        /// This public domain is temporarily used until documents.developers.rakuten.com is fixed
        static let domain = "digitalfox.fr"
        // static let domain = "documents.developers.rakuten.com"
    }

    private var refAccountIdentifier: Int64 {
        guard accountId == 0 else {
            return accountId
        }
        return (Bundle.main.object(forInfoDictionaryKey: "RATAccountIdentifier") as? NSNumber)!.int64Value
    }

    private var refApplicationIdentifier: Int64 {
        guard serviceId == 0 else {
            return serviceId
        }
        return (Bundle.main.object(forInfoDictionaryKey: "RATAppIdentifier") as? NSNumber)!.int64Value
    }

    private var parameters: String {
        let link = "campaignCode"
        let component = "news"
        let customParameters = "custom_param1=japan&custom_param2=tokyo"
        return "ref_acc=\(refAccountIdentifier)&ref_aid=\(refApplicationIdentifier)&ref_link=\(link)&ref_comp=\(component)&\(customParameters)"
    }

    private var demoAppURL: URL? {
        URL(string: "demoapp://?\(parameters)")
    }

    private var demoAppUniversalLinkURL: URL? {
        URL(string: "https://\(Constants.domain)?ref=\(Constants.bundleIdentifier)&\(parameters)")
    }

    @IBOutlet weak var spoolButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        guard let accountId = Bundle.main.infoDictionary?["RATAccountIdentifier"] as? Int64,
              let serviceId = Bundle.main.infoDictionary?["RATAppIdentifier"] as? Int64 else {
            return
        }
        self.accountId = accountId
        self.serviceId = serviceId
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

        if let accountIdString = dict[GlobalConstants.kRATAccountID] as? String,
           let accountId = Int64(accountIdString),
           !accountIdString.isEmpty {
            self.accountId = accountId
        }

        if let appIdString = dict[GlobalConstants.kRATAppID] as? String,
           let appId = Int64(appIdString),
           !appIdString.isEmpty {
            self.serviceId = appId
        }
    }

    @IBAction func spool(_ sender: Any) {
        RAnalyticsRATTracker.shared().event(withEventType: "SampleEvent",
                                            parameters: ["foo": "bar",
                                                         "acc": self.accountId,
                                                         "aid": self.serviceId]).track()

        if #available(iOS 11.0, *) {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
                _ = cookies.map { (cookie) in
                    print(cookie)
                }
            }
            // For quick testing of _RAnalyticsCookieInjector load a zero-frame webview
            WKWebView(frame: .zero).load(URLRequest(url: URL(string: "https://corp.rakuten.co.jp")!))
        }
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

        cell.delegate = self
        cell.title = cellType.title
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cellType = TableViewCellType(rawValue: indexPath.row) else {
            return
        }

        switch cellType {
        case .urlScheme:
            guard let url = demoAppURL,
                  UIApplication.shared.canOpenURL(url) else {
                UIAlertController.showError("Could not open URL Scheme", from: self)
                return
            }
            UIApplication.shared.open(url, options: [:])

        case .universalLink:
            guard let url = demoAppUniversalLinkURL,
                  UIApplication.shared.canOpenURL(url) else {
                UIAlertController.showError("Could not open Universal Link", from: self)
                return
            }
            UIApplication.shared.open(url, options: [:])

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
