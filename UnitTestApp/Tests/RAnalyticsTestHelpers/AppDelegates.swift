import Foundation
import UIKit

// MARK: - AppDelegating protocol

protocol AppDelegating {
    static var willFinishLaunchingIsCalled: Bool { get set }
    static var didFinishLaunchingIsCalled: Bool { get set }
}

// MARK: - AppDelegates swizzled by IceBase

final class SwizzledEmptyAppDelegate: UIResponder, UIApplicationDelegate {
    let iceBase = IceBase()

    override init() {
        super.init()
        iceBase.configureForAppDelegateClass(type(of: self))
    }
}

final class SwizzledPartialAppDelegateWillLaunch: UIResponder, UIApplicationDelegate, AppDelegating {
    static var willFinishLaunchingIsCalled = false
    static var didFinishLaunchingIsCalled = false

    let iceBase = IceBase()

    override init() {
        super.init()
        iceBase.configureForAppDelegateClass(type(of: self))
    }

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        type(of: self).willFinishLaunchingIsCalled = true
        return true
    }
}

final class SwizzledPartialAppDelegateDidLaunch: UIResponder, UIApplicationDelegate, AppDelegating {
    static var willFinishLaunchingIsCalled = false
    static var didFinishLaunchingIsCalled = false

    let iceBase = IceBase()

    override init() {
        super.init()
        iceBase.configureForAppDelegateClass(type(of: self))
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        type(of: self).didFinishLaunchingIsCalled = true
        return true
    }
}

final class SwizzledFullAppDelegate: UIResponder, UIApplicationDelegate, AppDelegating {
    static var willFinishLaunchingIsCalled = false
    static var didFinishLaunchingIsCalled = false

    let iceBase = IceBase()

    override init() {
        super.init()
        iceBase.configureForAppDelegateClass(type(of: self))
    }

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        type(of: self).willFinishLaunchingIsCalled = true
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        type(of: self).didFinishLaunchingIsCalled = true
        return true
    }
}

// MARK: - AppDelegates not swizzled by IceBase

final class EmptyAppDelegate: UIResponder, UIApplicationDelegate {
}

final class PartialAppDelegateWillLaunch: UIResponder, UIApplicationDelegate, AppDelegating {
    static var willFinishLaunchingIsCalled = false
    static var didFinishLaunchingIsCalled = false

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        type(of: self).willFinishLaunchingIsCalled = true
        return true
    }
}

final class PartialAppDelegateDidLaunch: UIResponder, UIApplicationDelegate, AppDelegating {
    static var willFinishLaunchingIsCalled = false
    static var didFinishLaunchingIsCalled = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        type(of: self).didFinishLaunchingIsCalled = true
        return true
    }
}

final class FullAppDelegate: UIResponder, UIApplicationDelegate, AppDelegating {
    static var willFinishLaunchingIsCalled = false
    static var didFinishLaunchingIsCalled = false

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        type(of: self).willFinishLaunchingIsCalled = true
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        type(of: self).didFinishLaunchingIsCalled = true
        return true
    }
}
