import UIKit

class SwitchTableViewCell: BaseTableViewCell {
    @IBOutlet weak var usingSwitch: UISwitch!

    @IBAction func valueChanged(_ sender: Any) {
        let value = self.usingSwitch.isOn
        self.update(value)
    }
}
