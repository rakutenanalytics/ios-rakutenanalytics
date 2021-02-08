// MARK: - Dependencies Factory

@objc public protocol DependenciesFactory {
    var httpCookieStore: WKHTTPCookieStorable? { get }
    var adIdentifierManager: AdvertisementIdentifiable? { get }
    var notificationHandler: NotificationObservable? { get }
    var userStorageHandler: UserStorageHandleable? { get }
    var keychainHandler: KeychainHandleable? { get }
    var tracker: Trackable? { get }
}

extension AnyDependenciesContainer: DependenciesFactory {
    public var httpCookieStore: WKHTTPCookieStorable? { resolve(WKHTTPCookieStorable.self) }
    public var adIdentifierManager: AdvertisementIdentifiable? { resolve(AdvertisementIdentifiable.self) }
    public var notificationHandler: NotificationObservable? { resolve(NotificationObservable.self) }
    public var userStorageHandler: UserStorageHandleable? { resolve(UserStorageHandleable.self) }
    public var keychainHandler: KeychainHandleable? { resolve(KeychainHandleable.self) }
    public var tracker: Trackable? { resolve(Trackable.self) }
}
