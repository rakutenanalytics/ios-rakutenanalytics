import UIKit
import RAnalytics
import WebKit

struct GlobalConstants {
    static let kLocationTracking = "Location_Tracking"
    static let kIDFATracking = "IDFA_Tracking"
    static let kRATAccountID = "RAT_Account_ID"
    static let kRATAppID = "RAT_App_ID"
}

class TableViewController: UITableViewController, BaseCellDelegate {

    var accountId: Int64 = 0
    var serviceId: Int64 = 0

    @IBOutlet weak var spoolButton: UIBarButtonItem!

    let titles: [String] = [
        GlobalConstants.kLocationTracking,
        GlobalConstants.kIDFATracking,
        GlobalConstants.kRATAccountID,
        GlobalConstants.kRATAppID
    ]

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
        return self.titles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = indexPath.row < 2 ? "SwitchTableViewCell" : "TextFieldTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BaseTableViewCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        cell.title = self.titles[indexPath.row]
        return cell
    }
}
