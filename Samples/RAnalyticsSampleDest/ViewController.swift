import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Bundle.main.infoDictionary?["CFBundleName"] as? String
    }
}
