import Quick
import Nimble
@testable import RAnalytics

final class BundleMock: EnvironmentBundle {
    var useDefaultSharedCookieStorage: Bool {
        (dictionary?["RATDisableSharedCookieStorage"] as? Bool) ?? false
    }
    var endpointAddress: URL? { mutableEndpointAddress }
    var enableInternalSerialization: Bool { mutableEnableInternalSerialization }
    static var assetsBundle: Bundle? { nil }
    static var sdkComponentMap: NSDictionary? { nil }

    var dictionary: [String: Any]?
    var mutableEndpointAddress: URL?
    var mutableEnableInternalSerialization: Bool = false
}

extension BundleMock: Bundleable {
    func object(forInfoDictionaryKey key: String) -> Any? { dictionary?[key] }
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
                let bundleMock = BundleMock()
                bundleMock.dictionary?["RATDisableSharedCookieStorage"] = false
                let httpRequest = URLRequest.ratRequest(url: URL(string: urlString)!, body: data, environmentBundle: bundleMock)

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
                    // swiftlint:disable:next force_try
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
                let input = [["key1": "value1", "key2": "value2"],
                             ["key3": "value3", "key4": ["key5": [["key6": "value6"], ["key7": "value7"]]]],
                             ["flag1": true],
                             ["flag2": false],
                             ["nullable1": nil],
                             ["price1": 3.57],
                             ["price": [nil, nil, nil, 41.65, 59.5, 22, 23.35, 9.99, 21.99, 21.41, 17.87, 19.99, 49.99, 41.65, 24.99]],
                             ["any1": [nil, nil, nil, "domain.com", 58, 34.56, true, false, [0, 1, 2, 3, 4, 5], ["user": ["name": "john"]]]],
                             ["emptyArray": []],
                             ["emptyDict": [:]],
                             ["nullable2": nil],
                             ["price2": 5]] as [JsonRecord]

                context("when internalSerialization is false") {
                    it("should return valid data") {
                        expect(Data(ratJsonRecords: input, internalSerialization: false)).toNot(beNil())
                    }

                    it("should return data with correct values except for Float numbers") {
                        let data = Data(ratJsonRecords: input, internalSerialization: false)!
                        let jsonString = String(data: data, encoding: .utf8)
                        verifyValues(from: jsonString)
                        expect(jsonString?.contains(#"{"price1":3.57}"#)).to(beFalse())
                    }

                    it("should return data with a valid JSON structure") {
                        verifyStructure(internalSerialization: false)
                    }
                }

                context("when internalSerialization is true") {
                    it("should return valid data") {
                        expect(Data(ratJsonRecords: input, internalSerialization: true)).toNot(beNil())
                    }

                    it("should return data with correct values") {
                        let data = Data(ratJsonRecords: input, internalSerialization: true)!
                        let jsonString = String(data: data, encoding: .utf8)
                        verifyValues(from: jsonString)
                        expect(jsonString?.contains(#"{"price1":3.57}"#)).to(beTrue())
                        // swiftlint:disable:next line_length
                        expect(jsonString?.contains(#"{"price":[null,null,null,41.65,59.5,22,23.35,9.99,21.99,21.41,17.87,19.99,49.99,41.65,24.99]}"#)).to(beTrue())
                        // swiftlint:disable:next line_length
                        expect(jsonString?.contains(#"{"any1":[null,null,null,"domain.com",58,34.56,true,false,[0,1,2,3,4,5],{"user":{"name":"john"}}]}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"emptyArray":[]}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"emptyDict":{}}"#)).to(beTrue())
                    }

                    it("should return data with a valid JSON structure") {
                        verifyStructure(internalSerialization: true)
                    }
                }

                func verifyValues(from jsonString: String?) {
                    expect(jsonString?.hasPrefix("cpkg_none=")).to(beTrue())
                    expect(jsonString?.contains(#""key1":"value1""#)).to(beTrue())
                    expect(jsonString?.contains(#""key2":"value2""#)).to(beTrue())
                    expect(jsonString?.contains(#""key3":"value3""#)).to(beTrue())
                    expect(jsonString?.contains(#""key6":"value6""#)).to(beTrue())
                    expect(jsonString?.contains(#""key7":"value7""#)).to(beTrue())
                    expect(jsonString?.contains(#"{"flag1":true}"#)).to(beTrue())
                    expect(jsonString?.contains(#"{"flag2":false}"#)).to(beTrue())
                    expect(jsonString?.contains(#"{"price2":5}"#)).to(beTrue())
                    expect(jsonString?.contains(#"{"nullable1":null}"#)).to(beTrue())
                    expect(jsonString?.contains(#"{"nullable2":null}"#)).to(beTrue())
                }

                func verifyStructure(internalSerialization: Bool) {
                    let str = String(data: Data(ratJsonRecords: input, internalSerialization: internalSerialization)!, encoding: .utf8)!
                    let jsonString = str["cpkg_none=".count..<str.count]
                    let jsonData = jsonString.data(using: .utf8)!
                    let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: .init(rawValue: 0))

                    expect(jsonObject).toNot(beNil())
                }
            }
        }
    }
}
