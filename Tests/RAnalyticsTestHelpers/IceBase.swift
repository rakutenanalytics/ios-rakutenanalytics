import Foundation
import UIKit

final class IceBaseManipulator: NSObject {
    static func addInstanceMethod(_ destinationSelector: Selector,
                                  with sourceSelector: Selector,
                                  fromClass: AnyClass,
                                  toClass: AnyClass) {
        let method: Method! = class_getInstanceMethod(fromClass, sourceSelector)
        let methodIMP = method_getImplementation(method)
        let types = method_getTypeEncoding(method)

        if class_addMethod(toClass, destinationSelector, methodIMP, types) {
            let originalMethod: Method! = class_getInstanceMethod(toClass, destinationSelector)

            class_replaceMethod(toClass,
                                sourceSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod))
        }
    }
}

final class IceBase: NSObject, AppDelegating {
    private let willFinishLaunchingSelector = #selector(UIApplicationDelegate.application(_:willFinishLaunchingWithOptions:))
    private let didFinishLaunchingSelector = #selector(UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:))
    static var willFinishLaunchingIsCalled = false
    static var didFinishLaunchingIsCalled = false

    func configureForAppDelegateClass(_ appDelegateClass: AnyClass) {
        IceBaseManipulator.addInstanceMethod(willFinishLaunchingSelector,
                                             with: #selector(IceBase._ice_app(_:willFinishLaunchingWithOptions:)),
                                             fromClass: IceBase.self,
                                             toClass: appDelegateClass)

        IceBaseManipulator.addInstanceMethod(didFinishLaunchingSelector,
                                             with: #selector(IceBase._ice_app(_:didFinishLaunchingWithOptions:)),
                                             fromClass: IceBase.self,
                                             toClass: appDelegateClass)
    }

    @objc func _ice_app(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        type(of: self).willFinishLaunchingIsCalled = true
        return true
    }

    @objc func _ice_app(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        type(of: self).didFinishLaunchingIsCalled = true
        return true
    }
}
