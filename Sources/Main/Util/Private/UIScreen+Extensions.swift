import Foundation
import UIKit

protocol Screenable {
    var bounds: CGRect { get }
}

extension UIScreen: Screenable {}
