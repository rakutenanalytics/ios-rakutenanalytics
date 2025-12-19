import Testing
import UIKit
@testable import RakutenAnalytics

#if SWIFT_PACKAGE
// As UIApplication.shared is nil in Swift Package tests target, these tests are disabled.
#else
@Suite("AppDelegateTests", .serialized)
struct AppDelegateTests {
    static let willFinishLaunchingSelector = #selector(UIApplicationDelegate.application(_:willFinishLaunchingWithOptions:))
    static let didFinishLaunchingSelector = #selector(UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:))
    static let openURLSelector = #selector(UIApplicationDelegate.application(_:open:options:))
    static let continueUserActivitySelector = #selector(UIApplicationDelegate.application(_:continue:restorationHandler:))
    static let swizzledWillFinishLaunchingSelector = #selector(UIApplication.rAutotrackApplication(_:willFinishLaunchingWithOptions:))
    static let swizzledDidFinishLaunchingSelector = #selector(UIApplication.rAutotrackApplication(_:didFinishLaunchingWithOptions:))
    static let swizzledIceBaseWillFinishLaunchingSelector = #selector(IceBase._ice_app(_:willFinishLaunchingWithOptions:))
    static let swizzledIceBaseDidFinishLaunchingSelector = #selector(IceBase._ice_app(_:didFinishLaunchingWithOptions:))
    
    static var originalAppDelegate: UIApplicationDelegate?
    private static var suiteInitialized = false
    
    /// Equivalent of Quick's `beforeSuite`, implemented explicitly because Swift Testing does not
    /// call `setUpSuite`/`tearDownSuite` automatically.
    private static func ensureSuiteInitialized() {
        guard !suiteInitialized else { return }
        originalAppDelegate = UIApplication.shared.delegate
        IceBase.willFinishLaunchingIsCalled = false
        IceBase.didFinishLaunchingIsCalled = false
        suiteInitialized = true
    }
    
    /// Swift Testing does not guarantee that the host app has already installed the UIApplication
    /// delegate-setter hook (and calling `installAutoTrackingHooks()` here can *toggle* swizzling off
    /// if it was already installed).
    /// To make the migration deterministic, explicitly swizzle the delegate class after installing it.
    @MainActor
    private mutating func setApplicationDelegateForTest(_ delegate: (NSObject & UIApplicationDelegate)?) {
        UIApplication.shared.delegate = delegate
        
        guard let delegate else { return }
        
        // If the host app already has the UIApplication delegate-setter hook installed,
        // assigning `UIApplication.shared.delegate` will auto-swizzle *all* tracked delegate
        // selectors (including `openURL` and `continue userActivity`).
        //
        // In that situation, applying our manual swizzle a second time changes the selector
        // surface (notably for an "empty" delegate) and breaks expectations.
        if delegate.responds(to: Self.openURLSelector) || delegate.responds(to: Self.continueUserActivitySelector) {
            return
        }
        
        // Mirror `UIApplication.rAutotrackSetApplicationDelegate(_:)`'s "already extended" guard:
        // if the delegate already responds to the swizzled selectors, do nothing.
        guard !delegate.responds(to: Self.swizzledWillFinishLaunchingSelector), !delegate.responds(to: Self.swizzledDidFinishLaunchingSelector) else {
            return
        }
        
        let recipient = type(of: delegate)
        
        // This uses the production swizzling helper (`RAnalyticsClassManipulable.replaceMethod`)
        // which can add methods when the original selector isn't implemented by the delegate.
        UIApplication.replaceMethod(Self.willFinishLaunchingSelector, inClass: recipient, with: Self.swizzledWillFinishLaunchingSelector, onlyIfPresent: false)
        UIApplication.replaceMethod(Self.didFinishLaunchingSelector, inClass: recipient, with: Self.swizzledDidFinishLaunchingSelector, onlyIfPresent: false)
    }
    
    @MainActor
    mutating func setUp() {
        Self.ensureSuiteInitialized()
        UIApplication.shared.delegate = nil
    }
    
    @MainActor
    mutating func tearDown() {
        // IMPORTANT:
        // In the host-app test environment, `UIApplication.shared.delegate` is not guaranteed
        // to be a safe zeroing-weak reference. If we leave it pointing to a short-lived test
        // delegate (which can be deallocated right after the test returns), UIKit may crash later
        // on the main runloop when it tries to message/retain the delegate.
        //
        // So we always restore the original app delegate at the end of each test (Quick did this
        // in `afterSuite`, but there the test delegates lived longer and didn't trigger crashes).
        if let delegate = UIApplication.shared.delegate {
            let type = type(of: delegate)
            
            UIApplication.replaceMethod(Self.swizzledWillFinishLaunchingSelector, toClass: type, replacing: Self.willFinishLaunchingSelector)
            UIApplication.replaceMethod(Self.swizzledDidFinishLaunchingSelector, toClass: type, replacing: Self.didFinishLaunchingSelector)
        }
        
        UIApplication.shared.delegate = Self.originalAppDelegate
    }

    @Suite("when AppDelegate is not swizzled by other class (e.g. IceBase)")
    struct WhenAppDelegateNotSwizzledByOtherClassTests {
        @Suite("Empty AppDelegate")
        struct EmptyAppDelegateTests {
            let appDelegate = EmptyAppDelegate()

            @Test("should be swizzled as expected")
            @MainActor
            mutating func testIsSwizzledAsExpected() {
                var spec = AppDelegateTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                spec.setApplicationDelegateForTest(appDelegate)

                #expect(UIApplication.shared.delegate as? NSObject == appDelegate)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.willFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledWillFinishLaunchingSelector) == false)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.didFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledDidFinishLaunchingSelector) == false)
            }
        }

        @Suite("Partial AppDelegate with willFinishLaunching")
        struct PartialAppDelegateWithWillFinishLaunchingTests {
            let appDelegate = PartialAppDelegateWillLaunch()

            @Test("should be swizzled as expected")
            @MainActor
            mutating func testIsSwizzledAsExpected() {
                var spec = AppDelegateTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                spec.setApplicationDelegateForTest(appDelegate)

                #expect(UIApplication.shared.delegate as? NSObject == appDelegate)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.willFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledWillFinishLaunchingSelector) == true)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.didFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledDidFinishLaunchingSelector) == false)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).willFinishLaunchingIsCalled == true)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).didFinishLaunchingIsCalled == false)
            }
        }

        @Suite("Partial AppDelegate with didFinishLaunching")
        struct PartialAppDelegateWithDidFinishLaunchingTests {
            let appDelegate = PartialAppDelegateDidLaunch()

            @Test("should be swizzled as expected")
            @MainActor
            mutating func testIsSwizzledAsExpected() {
                var spec = AppDelegateTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                spec.setApplicationDelegateForTest(appDelegate)

                #expect(UIApplication.shared.delegate as? NSObject == appDelegate)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.willFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledWillFinishLaunchingSelector) == false)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.didFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledDidFinishLaunchingSelector) == true)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).willFinishLaunchingIsCalled == false)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).didFinishLaunchingIsCalled == true)
            }
        }

        @Suite("Full AppDelegate")
        struct FullAppDelegateTests {
            let appDelegate = FullAppDelegate()

            @Test("should be swizzled as expected")
            @MainActor
            mutating func testIsSwizzledAsExpected() {
                var spec = AppDelegateTests()
                spec.setUp()
                defer { spec.tearDown() }
                
                spec.setApplicationDelegateForTest(appDelegate)

                #expect(UIApplication.shared.delegate as? NSObject == appDelegate)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.willFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledWillFinishLaunchingSelector) == true)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.didFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledDidFinishLaunchingSelector) == true)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).willFinishLaunchingIsCalled == true)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).didFinishLaunchingIsCalled == true)
            }
        }
    }

    // This context has been added to check RAnalytics compatibility with Firebase swizzling
    @Suite("when AppDelegate is swizzled by other class (e.g. IceBase)")
    struct WhenAppDelegateSwizzledByOtherClassTests {
        mutating func tearDown() {
            IceBase.willFinishLaunchingIsCalled = false
            IceBase.didFinishLaunchingIsCalled = false
        }

        @Suite("Swizzled Empty AppDelegate")
        struct SwizzledEmptyAppDelegateTests {
            let appDelegate = SwizzledEmptyAppDelegate()

            @Test("should be swizzled as expected")
            @MainActor
            mutating func testIsSwizzledAsExpected() {
                var spec = AppDelegateTests()
                spec.setUp()
                defer {
                    spec.tearDown()
                    var parent = WhenAppDelegateSwizzledByOtherClassTests()
                    parent.tearDown()
                }
                
                spec.setApplicationDelegateForTest(appDelegate)

                #expect(UIApplication.shared.delegate as? NSObject == appDelegate)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.willFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledWillFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledIceBaseWillFinishLaunchingSelector) == true)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.didFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledDidFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledIceBaseDidFinishLaunchingSelector) == true)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                #expect(IceBase.willFinishLaunchingIsCalled == true)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                #expect(IceBase.didFinishLaunchingIsCalled == true)
            }
        }

        @Suite("Swizzled Partial AppDelegate with willFinishLaunching")
        struct SwizzledPartialAppDelegateWithWillFinishLaunchingTests {
            let appDelegate = SwizzledPartialAppDelegateWillLaunch()

            @Test("should be swizzled as expected")
            @MainActor
            mutating func testIsSwizzledAsExpected() {
                var spec = AppDelegateTests()
                spec.setUp()
                defer {
                    spec.tearDown()
                    var parent = WhenAppDelegateSwizzledByOtherClassTests()
                    parent.tearDown()
                }
                
                spec.setApplicationDelegateForTest(appDelegate)

                #expect(UIApplication.shared.delegate as? NSObject == appDelegate)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.willFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledWillFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledIceBaseWillFinishLaunchingSelector) == false)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.didFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledDidFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledIceBaseDidFinishLaunchingSelector) == true)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).willFinishLaunchingIsCalled == true)
                #expect(IceBase.willFinishLaunchingIsCalled == false)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).didFinishLaunchingIsCalled == false)
                #expect(IceBase.didFinishLaunchingIsCalled == true)
            }
        }

        @Suite("Swizzled Partial AppDelegate with didFinishLaunching")
        struct SwizzledPartialAppDelegateWithDidFinishLaunchingTests {
            let appDelegate = SwizzledPartialAppDelegateDidLaunch()

            @Test("should be swizzled as expected")
            @MainActor
            mutating func testIsSwizzledAsExpected() {
                var spec = AppDelegateTests()
                spec.setUp()
                defer {
                    spec.tearDown()
                    var parent = WhenAppDelegateSwizzledByOtherClassTests()
                    parent.tearDown()
                }
                
                spec.setApplicationDelegateForTest(appDelegate)

                #expect(UIApplication.shared.delegate as? NSObject == appDelegate)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.willFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledWillFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledIceBaseWillFinishLaunchingSelector) == true)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.didFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledDidFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledIceBaseDidFinishLaunchingSelector) == false)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).willFinishLaunchingIsCalled == false)
                #expect(IceBase.willFinishLaunchingIsCalled == true)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).didFinishLaunchingIsCalled == true)
                #expect(IceBase.didFinishLaunchingIsCalled == false)
            }
        }

        @Suite("Swizzled Full AppDelegate")
        struct SwizzledFullAppDelegateTests {
            let appDelegate = SwizzledFullAppDelegate()

            @Test("should be swizzled as expected")
            @MainActor
            mutating func testIsSwizzledAsExpected() {
                var spec = AppDelegateTests()
                spec.setUp()
                defer {
                    spec.tearDown()
                    var parent = WhenAppDelegateSwizzledByOtherClassTests()
                    parent.tearDown()
                }
                
                spec.setApplicationDelegateForTest(appDelegate)

                #expect(UIApplication.shared.delegate as? NSObject == appDelegate)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.willFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledWillFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledIceBaseWillFinishLaunchingSelector) == false)

                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.didFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledDidFinishLaunchingSelector) == true)
                #expect(UIApplication.shared.delegate?.responds(to: AppDelegateTests.swizzledIceBaseDidFinishLaunchingSelector) == false)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, willFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).willFinishLaunchingIsCalled == true)
                #expect(IceBase.willFinishLaunchingIsCalled == false)

                _ = UIApplication.shared.delegate?.application?(UIApplication.shared, didFinishLaunchingWithOptions: nil)
                #expect(type(of: appDelegate).didFinishLaunchingIsCalled == true)
                #expect(IceBase.didFinishLaunchingIsCalled == false)
            }
        }
    }
}
#endif
