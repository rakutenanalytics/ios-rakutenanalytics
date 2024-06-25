import UIKit
import RakutenAnalytics
import WebKit
import CoreLocation.CLLocationManager

enum GlobalConstants {
    static let kLocationTracking = "Location_Tracking"
    static let kIDFATracking = "IDFA_Tracking"
    static let kRATAccountID = "RAT_Account_ID"
    static let kRATAppID = "RAT_App_ID"
    static let kRATUrlScheme = "Open URL Scheme"
    static let kRATUniversalLink = "Open Universal Link"
    static let enableAppUserAgent = "Enable App user agent"
    static let showWebViewUserAgent = "Show WKWebView's user agent"
    static let startLocationCollection = "Start Location Collection"
    static let requestGeoLocation = "Request Geo Location"
    static let showEmptyPage = "Show empty page (for pv event tests)"
    static let emptyPageTitle = "Empty page"
    static let urlSchemeLocator = "appToAppTracking_button_urlScheme"
    static let universalLinkLocator = "appToAppTracking_button_universalLink"
}

enum TableViewCellType: Int, CaseIterable {
    case location,
         idfa,
         accountID,
         appID,
         urlScheme,
         universalLink,
         enableAppUserAgent,
         showWebViewUserAgent,
         requestGeoLocation,
         startLocationCollection,
         showEmptyPage

    var cellIdentifier: String {
        switch self {
        case .location, .idfa, .enableAppUserAgent, .startLocationCollection:
            return "SwitchTableViewCell"
        case .accountID, .appID:
            return "TextFieldTableViewCell"
        case .urlScheme, .universalLink, .showWebViewUserAgent, .requestGeoLocation, .showEmptyPage:
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
        case .requestGeoLocation:
            return GlobalConstants.requestGeoLocation
        case .startLocationCollection:
            return GlobalConstants.startLocationCollection
        case .showEmptyPage:
            return GlobalConstants.showEmptyPage
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
    private let locationManager = CLLocationManager()
    private let successTitle = "Success"
    private let errorTitle = "Error"

    enum UserDefaultsKeys {
        static let locationCollectionKey = "GeoLocationCollection"
    }

    enum Constants {
        static let domain = "check.rat.rakuten.co.jp"
    }

    @IBOutlet weak var spoolButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        webView = WKWebView(frame: view.bounds)
        navigationItem.title = Bundle.main.infoDictionary?["CFBundleName"] as? String
        locationManager.requestAlwaysAuthorization()
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

        if let value = dict[GlobalConstants.startLocationCollection],
           let flag = value as? Bool {
            if flag {
                UserDefaults.standard.set(flag, forKey: UserDefaultsKeys.locationCollectionKey)
                GeoManager.shared.startLocationCollection()
            } else {
                UserDefaults.standard.set(flag, forKey: UserDefaultsKeys.locationCollectionKey)
                GeoManager.shared.stopLocationCollection()
            }
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

        if cell is SwitchTableViewCell && cellType == .startLocationCollection {
            let value = UserDefaults.standard.bool(forKey: UserDefaultsKeys.locationCollectionKey)
            (cell as? SwitchTableViewCell)?.usingSwitch.isOn = value
        }
        
        if cell is SwitchTableViewCell && cellType == .urlScheme {
            cell.contentView.accessibilityIdentifier = GlobalConstants.urlSchemeLocator
            cell.titleLabel.accessibilityIdentifier = GlobalConstants.urlSchemeLocator
        }
        
        if cell is SwitchTableViewCell && cellType == .universalLink {
            cell.contentView.accessibilityIdentifier = GlobalConstants.universalLinkLocator
            cell.titleLabel.accessibilityIdentifier = GlobalConstants.universalLinkLocator
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
                UIAlertController.show(errorTitle, message: "Could not open URL Scheme", from: self)
                return
            }
            UIApplication.shared.open(url, options: [:])

        case .universalLink:
            guard let url = model.universalLink(domain: Constants.domain),
                  UIApplication.shared.canOpenURL(url) else {
                UIAlertController.show(errorTitle, message: "Could not open Universal Link", from: self)
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

        case .requestGeoLocation:
            GeoManager.shared.requestLocation { result in
                switch result {
                case .success(let location):
                    UIAlertController.show(self.successTitle,
                                           message: "A geo location was returned: \(location.latitude), \(location.longitude)",
                                           from: self)

                case .failure(let error):
                    UIAlertController.show(self.errorTitle,
                                           message: "An error occured while requesting the geo location: \(error.localizedDescription)",
                                           from: self)
                }
            }

        case .showEmptyPage:
            let viewController = UIViewController()
            viewController.title = GlobalConstants.emptyPageTitle
            navigationController?.pushViewController(viewController, animated: true)

        default: ()
        }
    }
}

// MARK: - Alert

private extension UIAlertController {
    static func show(_ title: String, message: String, from viewController: UIViewController) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        viewController.present(alertController, animated: true)
    }
}
