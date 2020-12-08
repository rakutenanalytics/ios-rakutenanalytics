import Quick
import Nimble

final class RATUrlRequestExtensionSpec: QuickSpec {
    override func spec() {
        describe("ratRequest") {
            let urlString = "https://www.example.com"
            let data = "foo".data(using: .utf8)!
            let request = NSURLRequest.ratRequest(url: URL(string: urlString)!, body: data)

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

            it("should return a request with httpShouldHandleCookies set to expected value") {
                // FIXME: Due to structure of bundle helpers we cannot inject the value
                //expect(request.httpShouldHandleCookies).to(equal(true))
            }
        }
    }
}

final class RATArrayExtensionSpec: QuickSpec {
    override func spec() {
        describe("init") {
            context("when the passed in array elements are serialized json objects") {
                it("should return an array of the expected json dictionary elements") {
                    let dictionaryData = try! JSONSerialization.data(withJSONObject: ["key": "value"], options: .init(rawValue: 0))
                    let dataArray = [dictionaryData as NSData, dictionaryData as NSData]
                    let expected = [["key": "value"], ["key": "value"]] as NSArray

                    expect(NSMutableArray(ratDataRecords: dataArray)).to(equal(expected))
                }
            }

            context("when the input array elements are not serialized json objects") {
                it("should return an empty array") {
                    let dataArray = ["a", "b"].compactMap({ $0.data(using: .utf8) as NSData? })

                    expect(NSMutableArray(ratDataRecords: dataArray)).to(beEmpty())
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
                    expect(NSMutableData(ratRecords: [["key1": "value1"], ["key2": "value2"]])).toNot(beNil())
                }
            }
        }
    }
}

