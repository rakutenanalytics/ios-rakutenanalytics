import Foundation
import Testing
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif
@testable import RakutenAnalytics

@Suite("URLSessionExtensions")
struct URLSessionExtensionsTests {

    @Suite("Sessionable URLSession extension")
    struct SessionableURLSessionExtensionTests {
        let session = URLSession.shared

        @Test("data(for:) routes through dataTask for swizzle-compatible networking")
        func testDataForRoutesThroughDataTask() async throws {
            // Satisfied by the URLSession extension that bridges through dataTask(with:completionHandler:).
            let sessionable: Sessionable = session
            #expect(sessionable is URLSession)
        }
    }

    @Suite("SwiftySessionable default implementation")
    struct SwiftySessionableDefaultImplementationTests {
        fileprivate let session = SwiftySessionableMock()

        @Test("data(for:) returns data and response on success")
        func testDataForSuccess() async throws {
            let request = URLRequest(url: URL(string: "http://localhost")!)
            let expectedData = "data".data(using: .ascii)!
            let expectedResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)

            session.stubData = expectedData
            session.stubResponse = expectedResponse

            let (data, response) = try await session.data(for: request)
            #expect(data == expectedData)
            #expect(response == expectedResponse)
        }

        @Test("data(for:) throws on error")
        func testDataForError() async throws {
            let request = URLRequest(url: URL(string: "http://localhost")!)
            let expectedError = NSError(domain: "test", code: 5, userInfo: nil)

            session.stubError = expectedError

            do {
                _ = try await session.data(for: request)
                Issue.record("Expected error to be thrown")
            } catch {
                #expect((error as NSError) == expectedError)
            }
        }
    }
}

private final class SwiftySessionableMock: SwiftySessionable, @unchecked Sendable {
    var stubData: Data?
    var stubResponse: URLResponse?
    var stubError: Error?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let stubError {
            throw stubError
        }
        guard let stubResponse else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown)
        }
        return (stubData ?? Data(), stubResponse)
    }
}
