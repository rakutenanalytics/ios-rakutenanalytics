import UIKit
import RAnalytics

struct GlobalConstants {
    static let kStaging = "Staging"
    static let kLocationTracking = "Location_Tracking"
    static let kIDFATracking = "IDFA_Tracking"
    static let kRATAccountID = "RAT_Account_ID"
    static let kRATAppID = "RAT_App_ID"
}

class TableViewController: UITableViewController, BaseCellDelegate {

    var accountId: Int64 = 0
    var serviceId: Int64 = 0

    @IBOutlet weak var spoolButton: UIBarButtonItem!

    let titles: [String] = [GlobalConstants.kStaging, GlobalConstants.kLocationTracking, GlobalConstants.kIDFATracking, GlobalConstants.kRATAccountID, GlobalConstants.kRATAppID]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        self.accountId = Bundle.main.infoDictionary?["RATAccountIdentifier"] as! Int64
        self.serviceId = Bundle.main.infoDictionary?["RATAppIdentifier"] as! Int64
    }

    func update(_ dict: [String : Any]) {
        if let value = dict[GlobalConstants.kStaging] {
            let value = value as! Bool
            AnalyticsManager.shared().shouldUseStagingEnvironment = value
        }

        if let value = dict[GlobalConstants.kLocationTracking] {
            let value = value as! Bool
            AnalyticsManager.shared().shouldTrackLastKnownLocation = value
        }

        if let value = dict[GlobalConstants.kIDFATracking] {
            let value = value as! Bool
            AnalyticsManager.shared().shouldTrackAdvertisingIdentifier = value
        }

        if let value = dict[GlobalConstants.kRATAccountID] {
            let value = value as! String
            if !value.isEmpty {
                let accountId = Int64(value)!
                self.accountId = accountId
            }
        }

        if let value = dict[GlobalConstants.kRATAppID] {
            let value = value as! String
            if !value.isEmpty {
                let appId = Int64(value)!
                self.serviceId = appId
            }
        }
    }

    @IBAction func spool(_ sender: Any) {
        RAnalyticsRATTracker.shared().event(withEventType: "SampleEvent", parameters: ["foo": "bar",
                                                                                       "acc": self.accountId,
                                                                                       "aid": self.serviceId]).track()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: BaseTableViewCell
        let cellIdentifier = indexPath.row < 3 ? "SwitchTableViewCell" : "TextFieldTableViewCell"
        cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! BaseTableViewCell
        cell.delegate = self
        cell.title = self.titles[indexPath.row]
        return cell
    }
}
