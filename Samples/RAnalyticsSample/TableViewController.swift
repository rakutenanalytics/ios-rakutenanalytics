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
    private let demoAppURL = URL(string: "demoapp://")
    //private let demoAppUniversalLinkURL = URL(string: "https://documents.developers.rakuten.com")
    private let demoAppUniversalLinkURL = URL(string: "digitalfox.fr") // This public domain is temporarily used until documents.developers.rakuten.com is fixed

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
