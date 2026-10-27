import Foundation

protocol WKHTTPCookieStorable {
    @MainActor func allCookies() async -> [HTTPCookie]
    @MainActor func set(cookie: HTTPCookie) async
    @MainActor func delete(cookie: HTTPCookie) async
}

#if os(iOS)
import WebKit.WKHTTPCookieStore

extension WKHTTPCookieStore: WKHTTPCookieStorable {
    @MainActor
    func allCookies() async -> [HTTPCookie] {
        await withCheckedContinuation { continuation in
            self.getAllCookies { continuation.resume(returning: $0) }
        }
    }

    @MainActor
    func set(cookie: HTTPCookie) async {
        await withCheckedContinuation { continuation in
            self.setCookie(cookie) { continuation.resume() }
        }
    }

    @MainActor
    func delete(cookie: HTTPCookie) async {
        await withCheckedContinuation { continuation in
            self.delete(cookie) { continuation.resume() }
        }
    }
}
#endif

#if os(tvOS)

/// Stub used on tvOS where WebKit is unavailable.
final class NoOpWKHTTPCookieStore: WKHTTPCookieStorable {
    @MainActor
    func allCookies() async -> [HTTPCookie] {
        []
    }

    @MainActor
    func set(cookie _: HTTPCookie) async {
        // No-op: WebKit cookie store is unavailable on tvOS.
    }

    @MainActor
    func delete(cookie _: HTTPCookie) async {
        // No-op: WebKit cookie store is unavailable on tvOS.
    }
}

#endif
