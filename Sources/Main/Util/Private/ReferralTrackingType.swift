import Foundation
import UIKit

enum ReferralTrackingType: Hashable {
    case none
    case page(currentPage: UIViewController?) // Currently-visited UIKit view controller.
    case swiftuiPage(pageName: String) // Currently-visited SwiftUI view.
    case referralApp(ReferralAppModel)
}
