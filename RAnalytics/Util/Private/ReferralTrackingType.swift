import Foundation
import UIKit

enum ReferralTrackingType: Hashable {
    case none
    case page(currentPage: UIViewController?) // Currently-visited view controller.
    case referralApp(ReferralAppModel)
}
