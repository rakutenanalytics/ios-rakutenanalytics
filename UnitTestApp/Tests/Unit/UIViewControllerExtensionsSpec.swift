import Quick
import Nimble
@testable import RakutenAnalytics
import UIKit

final class UIViewControllerExtensionsSpec: QuickSpec {
    override class func spec() {
        describe("UIViewController extensions") {
            describe("isTrackableAsPageVisit") {
                context("When view controller type is UINavigationController") {
                    it("should return false") {
                        expect(UINavigationController().isTrackableAsPageVisit).to(beFalse())
                    }
                }

                context("When view controller type is UISplitViewController") {
                    it("should return false") {
                        expect(UISplitViewController().isTrackableAsPageVisit).to(beFalse())
                    }
                }

                context("When view controller type is UIPageViewController") {
                    it("should return false") {
                        expect(UIPageViewController().isTrackableAsPageVisit).to(beFalse())
                    }
                }

                context("When view controller type is UITabBarController") {
                    it("should return false") {
                        expect(UITabBarController().isTrackableAsPageVisit).to(beFalse())
                    }
                }

                context("When view controller type is UIAlertController") {
                    it("should return false") {
                        expect(UIAlertController().isTrackableAsPageVisit).to(beFalse())
                    }
                }

                func verifyPageTracking(for viewController: UIViewController) {
                    context("When view type is UIView") {
                        context("When view controller is not added to window") {
                            it("should return true") {
                                viewController.view = UIView()
                                expect(viewController.view.window).to(beNil())
                                expect(viewController.isTrackableAsPageVisit).to(beTrue())
                            }
                        }

                        context("When rootViewController is set") {
                            it("should return true") {
                                viewController.view = UIView()
                                let window = UIWindow()
                                window.rootViewController = viewController
                                window.makeKeyAndVisible()
                                expect(viewController.view.window).toNot(beNil())
                                expect(viewController.isTrackableAsPageVisit).to(beTrue())
                            }
                        }
                    }

                    context("When view is nil") {
                        afterEach {
                            UIViewController.swizzleToggle()
                        }

                        it("should return true (and should not crash)") {
                            // Even if UIViewController's view is set to nil, the view value remains to be a UIView instance.
                            // Swizzling here helps to (force) set the view to nil and test this behaviour as expected.
                            UIViewController.swizzleToggle()
                            expect(viewController.view).to(beNil())
                            expect(viewController.isTrackableAsPageVisit).to(beTrue())
                        }
                    }
                }

                context("When view controller type is UIViewController") {
                    verifyPageTracking(for: UIViewController())
                }

                context("When view controller type is UITableViewController") {
                    verifyPageTracking(for: UITableViewController())
                }
            }
        }
    }
}

private extension UIViewController {
    @objc var swizzledView: UIView! {
        nil
    }

    static func swizzleToggle() {
        guard let originalMethod = class_getInstanceMethod(Self.self,
                                                           #selector(getter: view)),
              let swizzledMethod = class_getInstanceMethod(Self.self,
                                                           #selector(getter: swizzledView)) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
