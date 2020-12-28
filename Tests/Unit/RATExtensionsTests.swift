import Quick
import Nimble
@testable import RAnalytics

class BundleMock: EnvironmentBundle {
    static var shouldUseDefaultCookieStorage = true

    static var useDefaultSharedCookieStorage: Bool { shouldUseDefaultCookieStorage }
    static var endpointAddress: URL? { nil }
    static var assetsBundle: Bundle? { nil }
    static var sdkComponentMap: NSDictionary? { nil }
}

final class RATUrlRequestExtensionSpec: QuickSpec {
    override func spec() {
        describe("ratRequest") {
            let urlString = "https://www.example.com"
            let data = "foo".data(using: .utf8)!
            let request = URLRequest.ratRequest(url: URL(string: urlString)!, body: data)

            it("should return a request with passed-in url set") {
                expect(request.url?.absoluteString).to(equal(urlString))
            }

            it("should return a request with passed-in data set as body") {
                expect(request.httpBody).to(equal(data))
            }

            it("should return a request with timeout of 30s") {
                expect(request.timeoutInterval).to(equal(30.0))
            }

            it("should return a request set to reload ignoring cache") {
                expect(request.cachePolicy).to(equal(.reloadIgnoringCacheData))
            }

            it("should return a request with context type header set to text/plain") {
                expect(request.allHTTPHeaderFields?["Content-Type"]).to(equal("text/plain"))
            }

            it("should return a request with POST method set") {
                expect(request.httpMethod).to(equal("POST"))
            }

            it("should return a request with content length header set to expected value") {
                expect(request.allHTTPHeaderFields?["Content-Length"]).to(equal("\(data.count)"))
            }

            it("should return a request with httpShouldHandleCookies set false") {
                BundleMock.shouldUseDefaultCookieStorage = false
                let httpRequest = URLRequest.ratRequest(url: URL(string: urlString)!, body: data, environmentBundle: BundleMock.self)

                expect(httpRequest.httpShouldHandleCookies).to(equal(false))
            }
        }
    }
}

final class RATArrayExtensionSpec: QuickSpec {
    override func spec() {
        describe("init") {
            context("when the passed in array elements are serialized json dictionaries") {
                it("should return an array of the expected json dictionary elements") {
                    let dictionaryData = try! JSONSerialization.data(withJSONObject: ["key": "value"], options: .init(rawValue: 0))
                    let dataArray = [dictionaryData, dictionaryData]
                    let expected = [["key": "value"], ["key": "value"]]

                    expect([JsonRecord](ratDataRecords: dataArray) as? Array).to(equal(expected))
                }
            }

            context("when the input array elements are not serialized json dictionaries") {
                it("should return a nil array") {
                    let dataArray = ["a", "b"].compactMap({ $0.data(using: .utf8) as Data? })

                    expect([JsonRecord](ratDataRecords: dataArray)).to(beNil())
                }
            }
        }
    }
}

final class RATDataExtensionSpec: QuickSpec {
    override func spec() {
        describe("init") {
            context("when the input array elements are dictionaries") {
                it("should return valid data") {
                    let input = [["key1": "value1", "key2": "value2"], ["key3": "value3"]] as [JsonRecord]
                    expect(Data(ratJsonRecords: input)).toNot(beNil())
                }
            }
        }
    }
}

