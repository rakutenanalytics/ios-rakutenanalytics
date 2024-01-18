import Quick
import Nimble
import UIKit
@testable import RakutenAnalytics

#if SWIFT_PACKAGE
// As UIApplication.shared is nil in Swift Package tests target, these tests are disabled.
#else
final class AppDelegateSpec: QuickSpec {
    override func spec() {
        describe("AppDelegateSpec") {
            var originalAppDelegate: UIApplicationDelegate?
            let willFinishLaunchingSelector = #selector(UIApplicationDelegate.application(_:willFinishLaunchingWithOptions:))
            let didFinishLaunchingSelector = #selector(UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:))
            let swizzledWillFinishLaunchingSelector = #selector(UIApplication.rAutotrackApplication(_:willFinishLaunchingWithOptions:))
            let swizzledDidFinishLaunchingSelector = #selector(UIApplication.rAutotrackApplication(_:didFinishLaunchingWithOptions:))
            let swizzledIceBaseWillFinishLaunchingSelector = #selector(IceBase._ice_app(_:willFinishLaunchingWithOptions:))
            let swizzledIceBaseDidFinishLaunchingSelector = #selector(IceBase._ice_app(_:didFinishLaunchingWithOptions:))

            beforeSuite {
                originalAppDelegate = UIApplication.shared.delegate
                IceBase.willFinishLaunchingIsCalled = false
                IceBase.didFinishLaunchingIsCalled = false
            }

            afterSuite {
                UIApplication.shared.rAutotrackSetApplicationDelegate(originalAppDelegate)
            }

            beforeEach {
                UIApplication.shared.delegate = nil
            }

            afterEach {
                if let delegate = UIApplication.shared.delegate {
                    let type = type(of: delegate)

                    UIApplication.replaceMethod(swizzledWillFinishLaunchingSelector,
                                                toClass: type,
                                                replacing: willFinishLaunchingSelector)

                    UIApplication.replaceMethod(swizzledDidFinishLaunchingSelector,
                                                toClass: type,
                                                replacing: didFinishLaunchingSelector)
                }
            }

            context("when AppDelegate is not swizzled by other class (e.g. IceBase)") {
                context("Empty AppDelegate") {
                    let appDelegate = EmptyAppDelegate()

                    it("should be swizzled as expected") {
                        UIApplication.shared.delegate = appDelegate

                        expect(UIApplication.shared.delegate as? NSObject).to(equal(appDelegate))

                        expect(UIApplication.shared.delegate?.responds(to: willFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledWillFinishLaunchingSelector)).to(beFalse())

                        expect(UIApplication.shared.delegate?.responds(to: didFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledDidFinishLaunchingSelector)).to(beFalse())
                    }
                }

                context("Partial AppDelegate with willFinishLaunching") {
                    let appDelegate = PartialAppDelegateWillLaunch()

                    it("should be swizzled as expected") {
                        UIApplication.shared.delegate = appDelegate

                        expect(UIApplication.shared.delegate as? NSObject).to(equal(appDelegate))

                        expect(UIApplication.shared.delegate?.responds(to: willFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledWillFinishLaunchingSelector)).to(beTrue())

                        expect(UIApplication.shared.delegate?.responds(to: didFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledDidFinishLaunchingSelector)).to(beFalse())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).willFinishLaunchingIsCalled).to(beTrue())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).didFinishLaunchingIsCalled).to(beFalse())
                    }
                }

                context("Partial AppDelegate with didFinishLaunching") {
                    let appDelegate = PartialAppDelegateDidLaunch()

                    it("should be swizzled as expected") {
                        UIApplication.shared.delegate = appDelegate

                        expect(UIApplication.shared.delegate as? NSObject).to(equal(appDelegate))

                        expect(UIApplication.shared.delegate?.responds(to: willFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledWillFinishLaunchingSelector)).to(beFalse())

                        expect(UIApplication.shared.delegate?.responds(to: didFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledDidFinishLaunchingSelector)).to(beTrue())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).willFinishLaunchingIsCalled).to(beFalse())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).didFinishLaunchingIsCalled).to(beTrue())
                    }
                }

                context("Full AppDelegate") {
                    let appDelegate = FullAppDelegate()

                    it("should be swizzled as expected") {
                        UIApplication.shared.delegate = appDelegate

                        expect(UIApplication.shared.delegate as? NSObject).to(equal(appDelegate))

                        expect(UIApplication.shared.delegate?.responds(to: willFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledWillFinishLaunchingSelector)).to(beTrue())

                        expect(UIApplication.shared.delegate?.responds(to: didFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledDidFinishLaunchingSelector)).to(beTrue())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).willFinishLaunchingIsCalled).to(beTrue())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).didFinishLaunchingIsCalled).to(beTrue())
                    }
                }
            }

            // This context has been added to check RAnalytics compatibility with Firebase swizzling
            context("when AppDelegate is swizzled by other class (e.g. IceBase)") {
                afterEach {
                    IceBase.willFinishLaunchingIsCalled = false
                    IceBase.didFinishLaunchingIsCalled = false
                }

                context("Swizzled Empty AppDelegate") {
                    let appDelegate = SwizzledEmptyAppDelegate()

                    it("should be swizzled as expected") {
                        UIApplication.shared.delegate = appDelegate

                        expect(UIApplication.shared.delegate as? NSObject).to(equal(appDelegate))

                        expect(UIApplication.shared.delegate?.responds(to: willFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledWillFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledIceBaseWillFinishLaunchingSelector)).to(beTrue())

                        expect(UIApplication.shared.delegate?.responds(to: didFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledDidFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledIceBaseDidFinishLaunchingSelector)).to(beTrue())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                        expect(IceBase.willFinishLaunchingIsCalled).to(beTrue())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                        expect(IceBase.didFinishLaunchingIsCalled).to(beTrue())
                    }
                }

                context("Swizzled Partial AppDelegate with willFinishLaunching") {
                    let appDelegate = SwizzledPartialAppDelegateWillLaunch()

                    it("should be swizzled as expected") {
                        UIApplication.shared.delegate = appDelegate

                        expect(UIApplication.shared.delegate as? NSObject).to(equal(appDelegate))

                        expect(UIApplication.shared.delegate?.responds(to: willFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledWillFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledIceBaseWillFinishLaunchingSelector)).to(beFalse())

                        expect(UIApplication.shared.delegate?.responds(to: didFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledDidFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledIceBaseDidFinishLaunchingSelector)).to(beTrue())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).willFinishLaunchingIsCalled).to(beTrue())
                        expect(IceBase.willFinishLaunchingIsCalled).to(beFalse())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).didFinishLaunchingIsCalled).to(beFalse())
                        expect(IceBase.didFinishLaunchingIsCalled).to(beTrue())
                    }
                }

                context("Swizzled Partial AppDelegate with didFinishLaunching") {
                    let appDelegate = SwizzledPartialAppDelegateDidLaunch()

                    it("should be swizzled as expected") {
                        UIApplication.shared.delegate = appDelegate

                        expect(UIApplication.shared.delegate as? NSObject).to(equal(appDelegate))

                        expect(UIApplication.shared.delegate?.responds(to: willFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledWillFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledIceBaseWillFinishLaunchingSelector)).to(beTrue())

                        expect(UIApplication.shared.delegate?.responds(to: didFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledDidFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledIceBaseDidFinishLaunchingSelector)).to(beFalse())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).willFinishLaunchingIsCalled).to(beFalse())
                        expect(IceBase.willFinishLaunchingIsCalled).to(beTrue())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).didFinishLaunchingIsCalled).to(beTrue())
                        expect(IceBase.didFinishLaunchingIsCalled).to(beFalse())
                    }
                }

                context("Swizzled Full AppDelegate") {
                    let appDelegate = SwizzledFullAppDelegate()

                    it("should be swizzled as expected") {
                        UIApplication.shared.delegate = appDelegate

                        expect(UIApplication.shared.delegate as? NSObject).to(equal(appDelegate))

                        expect(UIApplication.shared.delegate?.responds(to: willFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledWillFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledIceBaseWillFinishLaunchingSelector)).to(beFalse())

                        expect(UIApplication.shared.delegate?.responds(to: didFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledDidFinishLaunchingSelector)).to(beTrue())
                        expect(UIApplication.shared.delegate?.responds(to: swizzledIceBaseDidFinishLaunchingSelector)).to(beFalse())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).willFinishLaunchingIsCalled).to(beTrue())
                        expect(IceBase.willFinishLaunchingIsCalled).to(beFalse())

                        _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                        expect(type(of: appDelegate).didFinishLaunchingIsCalled).to(beTrue())
                        expect(IceBase.didFinishLaunchingIsCalled).to(beFalse())
                    }
                }
            }
        }
    }
}
#endif
