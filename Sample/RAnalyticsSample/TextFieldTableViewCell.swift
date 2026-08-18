import UIKit

class TextFieldTableViewCell: BaseTableViewCell, UITextFieldDelegate {
    @IBOutlet weak var textField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
        textField.addTarget(self, action: #selector(commitValue), for: .editingChanged)
    }

    override func update(title: String?) {
        super.update(title: title)
        guard let title = title else { return }

        switch title {
        case GlobalConstants.kRATAccountID:
            textField.placeholder = "123"
            if textField.text?.isEmpty != false,
               let accountId = Bundle.main.infoDictionary?["RATAccountIdentifier"] as? Int {
                textField.text = String(accountId)
            }
        case GlobalConstants.kRATAppID:
            textField.placeholder = "456"
            if textField.text?.isEmpty != false,
               let appId = Bundle.main.infoDictionary?["RATAppIdentifier"] as? Int {
                textField.text = String(appId)
            }
        case GlobalConstants.kRATUrlSchemePathComponent, GlobalConstants.kRATUniversalLinkPathComponent:
            textField.placeholder = "/path"
        case GlobalConstants.kRATUrlSchemeRef, GlobalConstants.kRATUniversalLinkRef:
            textField.placeholder = "ref"
        default:
            break
        }
    }

    func applyInputText(_ text: String?) {
        textField.text = text
    }

    @IBAction func valueChanged(_ sender: Any) {
        commitValue()
    }

    @objc func commitValue() {
        update(textField.text ?? "")
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        commitValue()
    }
}
