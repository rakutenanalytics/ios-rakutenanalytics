import Foundation
import Testing
@testable import RakutenAnalytics

@Suite("URLSessionExtensions")
struct URLSessionExtensionsSpec {
    
    @Suite("Sessionable URLSession extension")
    struct SessionableURLSessionExtensionTests {
        let session = URLSession.shared
        
        @Test("createDataTask() will properly create URLSessionTask object")
        func testCreateDataTask() {
            let request = URLRequest(url: URL(string: "http://localhost")!)
            let dataTask = session.createDataTask(with: request, completionHandler: { _, _, _ in })
            #expect(dataTask is URLSessionTask)
            #expect((dataTask as? URLSessionTask)?.currentRequest == request)
        }
    }
    
    @Suite("SwiftySessionable default implementation")
    struct SwiftySessionableDefaultImplementationTests {
        fileprivate let session = SwiftySessionableMock()
        
        @Test("will properly map completion handler - success")
        func testMapsCompletionHandlerSuccess() async throws {
            let request = URLRequest(url: URL(string: "http://localhost")!)
            let expectedData = "data".data(using: .ascii)!
            let expectedResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
            
            try await withCheckedThrowingContinuation { continuation in
                _ = session.dataTask(with: request) { result in
                    do {
                        let resultData = try result.get()
                        #expect(resultData.data == expectedData)
                        #expect(resultData.response == expectedResponse)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                session.callCompletionHandler?(expectedData, expectedResponse, nil)
            }
        }
        
        @Test("will properly map completion handler - error")
        func testMapsCompletionHandlerError() async throws {
            let request = URLRequest(url: URL(string: "http://localhost")!)
            let expectedError = NSError(domain: "test", code: 5, userInfo: nil)
            
            try await withCheckedThrowingContinuation { continuation in
                _ = session.dataTask(with: request) { result in
                    switch result {
                    case .failure(let error):
                        #expect((error as NSError) == expectedError)
                        continuation.resume()
                    case .success:
                        continuation.resume(throwing: NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Expected failure but got success"]))
                    }
                }
                session.callCompletionHandler?(nil, nil, expectedError)
            }
        }
        
        //                @Test("will throw an assertion if there was no error but there's no response object")
        //                func testThrowsAssertionWhenNoErrorButNoResponse() {
        //                    let request = URLRequest(url: URL(string: "http://localhost")!)
        //                    let expectedData = "data".data(using: .ascii)!
        //                    _ = session.dataTask(with: request) { _ in }
        //                    
        //                    expect(session.callCompletionHandler?(expectedData, nil, nil)).to(throwAssertion())
        //                }
    }
}

private class SwiftySessionableMock: URLSession, @unchecked Sendable {
    private(set) var callCompletionHandler: ((_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void)?
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.callCompletionHandler = completionHandler
        return URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
    }
}
