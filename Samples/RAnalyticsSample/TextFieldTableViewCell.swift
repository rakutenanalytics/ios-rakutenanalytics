import UIKit

class TextFieldTableViewCell: BaseTableViewCell {
    @IBOutlet weak var textField: UITextField!

    override func update(title: String?) {
        super.update(title: title)
        if title == GlobalConstants.kRATAccountID {
            if let accountId = Bundle.main.infoDictionary?["RATAccountIdentifier"] as? Int {
                self.textField.text = String(accountId)
            }
        } else if title == GlobalConstants.kRATAppID {
            if let appId = Bundle.main.infoDictionary?["RATAppIdentifier"] as? Int {
                self.textField.text = String(appId)
            }
        }
    }

    @IBAction func valueChanged(_ sender: Any) {
        if let value = self.textField.text {
            self.update(value)
        }
    }
}
