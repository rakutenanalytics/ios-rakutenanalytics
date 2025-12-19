import Testing
@testable import RakutenAnalytics
import UIKit

@Suite("UIViewController extensions")
struct UIViewControllerExtensionsTests {
    @Suite("isTrackableAsPageVisit")
    struct IsTrackableAsPageVisitTests {
        @Suite("When view controller type is UINavigationController")
        struct WhenViewControllerTypeIsUINavigationControllerTests {
            @Test("should return false")
            @MainActor
            func testShouldReturnFalse() {
                #expect(UINavigationController().isTrackableAsPageVisit == false)
            }
        }
        
        @Suite("When view controller type is UISplitViewController")
        struct WhenViewControllerTypeIsUISplitViewControllerTests {
            @Test("should return false")
            @MainActor
            func testShouldReturnFalse() {
                #expect(UISplitViewController().isTrackableAsPageVisit == false)
            }
        }
        
        @Suite("When view controller type is UIPageViewController")
        struct WhenViewControllerTypeIsUIPageViewControllerTests {
            @Test("should return false")
            @MainActor
            func testShouldReturnFalse() {
                #expect(UIPageViewController().isTrackableAsPageVisit == false)
            }
        }
        
        @Suite("When view controller type is UITabBarController")
        struct WhenViewControllerTypeIsUITabBarControllerTests {
            @Test("should return false")
            @MainActor
            func testShouldReturnFalse() {
                #expect(UITabBarController().isTrackableAsPageVisit == false)
            }
        }
        
        @Suite("When view controller type is UIAlertController")
        struct WhenViewControllerTypeIsUIAlertControllerTests {
            @Test("should return false")
            @MainActor
            func testShouldReturnFalse() {
                #expect(UIAlertController().isTrackableAsPageVisit == false)
            }
        }
        
        @Suite("When view controller type is UIViewController")
        struct WhenViewControllerTypeIsUIViewControllerTests {
            @Suite("When view type is UIView")
            struct WhenViewTypeIsUIViewTests {
                @Suite("When view controller is not added to window")
                struct WhenViewControllerIsNotAddedToWindowTests {
                    @Test("should return true")
                    @MainActor
                    func testShouldReturnTrue() {
                        let viewController = UIViewController()
                        viewController.view = UIView()
                        #expect(viewController.view.window == nil)
                        #expect(viewController.isTrackableAsPageVisit == true)
                    }
                }
                
                @Suite("When rootViewController is set")
                struct WhenRootViewControllerIsSetTests {
                    @Test("should return true")
                    @MainActor
                    func testShouldReturnTrue() {
                        let viewController = UIViewController()
                        viewController.view = UIView()
                        let window = UIWindow()
                        window.rootViewController = viewController
                        window.makeKeyAndVisible()
                        #expect(viewController.view.window != nil)
                        #expect(viewController.isTrackableAsPageVisit == true)
                    }
                }
            }
            
            @Suite("When view is nil")
            struct WhenViewIsNilTests {
                @Test("should return true (and should not crash)")
                @MainActor
                func testShouldReturnTrueAndShouldNotCrash() {
                    let viewController = UIViewController()
                    // Even if UIViewController's view is set to nil, the view value remains to be a UIView instance.
                    // Swizzling here helps to (force) set the view to nil and test this behaviour as expected.
                    UIViewController.swizzleToggle()
                    defer {
                        UIViewController.swizzleToggle()
                    }
                    #expect(viewController.view == nil)
                    #expect(viewController.isTrackableAsPageVisit == true)
                }
            }
        }
        
        @Suite("When view controller type is UITableViewController")
        struct WhenViewControllerTypeIsUITableViewControllerTests {
            @Suite("When view type is UIView")
            struct WhenViewTypeIsUIViewTests {
                @Suite("When view controller is not added to window")
                struct WhenViewControllerIsNotAddedToWindowTests {
                    @Test("should return true")
                    @MainActor
                    func testShouldReturnTrue() {
                        let viewController = UITableViewController()
                        viewController.view = UIView()
                        #expect(viewController.view.window == nil)
                        #expect(viewController.isTrackableAsPageVisit == true)
                    }
                }
                
                @Suite("When rootViewController is set")
                struct WhenRootViewControllerIsSetTests {
                    @Test("should return true")
                    @MainActor
                    func testShouldReturnTrue() {
                        let viewController = UITableViewController()
                        viewController.view = UIView()
                        let window = UIWindow()
                        window.rootViewController = viewController
                        window.makeKeyAndVisible()
                        #expect(viewController.view.window != nil)
                        #expect(viewController.isTrackableAsPageVisit == true)
                    }
                }
            }
            
            @Suite("When view is nil")
            struct WhenViewIsNilTests {
                @Test("should return true (and should not crash)")
                @MainActor
                func testShouldReturnTrueAndShouldNotCrash() {
                    let viewController = UITableViewController()
                    // Even if UIViewController's view is set to nil, the view value remains to be a UIView instance.
                    // Swizzling here helps to (force) set the view to nil and test this behaviour as expected.
                    UIViewController.swizzleToggle()
                    defer {
                        UIViewController.swizzleToggle()
                    }
                    #expect(viewController.view == nil)
                    #expect(viewController.isTrackableAsPageVisit == true)
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
        guard let originalMethod = class_getInstanceMethod(Self.self, #selector(getter: view)),
              let swizzledMethod = class_getInstanceMethod(Self.self, #selector(getter: swizzledView)) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
