// MARK: - Dependencies Factory

@objc public protocol DependenciesFactory {
    var httpCookieStore: WKHTTPCookieStorable? { get }
    var adIdentifierManager: AdvertisementIdentifiable? { get }
}

extension AnyDependenciesContainer: DependenciesFactory {
    public var httpCookieStore: WKHTTPCookieStorable? { resolve(WKHTTPCookieStorable.self) }
    public var adIdentifierManager: AdvertisementIdentifiable? { resolve(AdvertisementIdentifiable.self) }
}
