import Quick
import Nimble
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

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
            context("when the internal serializer serializes a big amount of data") {
                let jsonData = try? String(contentsOf: BundleHelper.ratJsonUrl!, encoding: .utf8).data(using: .utf8)
                let input = (try? JSONSerialization.jsonObject(with: jsonData!, options: []) as? [JsonRecord])!

                it("should not crash") {
                    let array = Array(repeating: input, count: 1000).flatMap { $0 }
                    let data = Data(ratJsonRecords: array, internalSerialization: true)
                    expect(data).toNot(beNil())
                }
            }

            context("when the input array elements are dictionaries") {
                let input = [["key1": "value1", "key2": "value2"],
                             ["key3": "value3", "key4": ["key5": [["key6": "value6"], ["key7": "value7"]]]],
                             ["flag1": true],
                             ["flag2": false],
                             ["nullable1": nil],
                             ["any1": [nil, nil, nil, "domain.com", 58, 34.56, true, false, [0, 1, 2, 3, 4, 5], ["user": ["name": "john"]]]],
                             ["emptyArray": []],
                             ["emptyDict": [:]],
                             ["nullable2": nil],
                             ["latitude": 35.59731937917094],
                             ["longitude": 139.62372840340936],
                             ["priceInt1": 5],
                             ["priceInt2": 50],
                             ["priceInt3": 500],
                             ["priceInt4": 5000],
                             ["priceInt5": 50000],
                             ["price1": 5.0],
                             ["price2": 5.10],
                             ["price3": 3.57],
                             ["price4": 9.99],
                             ["price5": 69.99],
                             ["prices1": [nil, nil, nil, 41.65, 59.5, 22, 23.35, 9.99, 21.99, 21.41, 17.87, 19.99, 49.99, 41.65, 24.99]],
                             ["prices2": [22, 3.5, 3.57, 8.965, 2.5463, 9.99]],
                             ["rewardsPrices": [69.99, 77.99, 79.99, 89.99, 99.99]]] as [JsonRecord]

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
                        // swiftlint:disable:next line_length
                        expect(jsonString?.contains(#"{"any1":[null,null,null,"domain.com",58,34.56,true,false,[0,1,2,3,4,5],{"user":{"name":"john"}}]}"#)).to(beTrue())

                        // Empty
                        expect(jsonString?.contains(#"{"emptyArray":[]}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"emptyDict":{}}"#)).to(beTrue())

                        // Location
                        expect(jsonString?.contains(#"{"latitude":35.59731937917094}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"longitude":139.62372840340936}"#)).to(beTrue())

                        // Prices
                        expect(jsonString?.contains(#"{"priceInt1":5}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"priceInt2":50}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"priceInt3":500}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"priceInt4":5000}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"priceInt5":50000}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"price1":5}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"price2":5.1}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"price3":3.57}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"price4":9.99}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"price5":69.99}"#)).to(beTrue())
                        // swiftlint:disable:next line_length
                        expect(jsonString?.contains(#"{"prices1":[null,null,null,41.65,59.5,22,23.35,9.99,21.99,21.41,17.87,19.99,49.99,41.65,24.99]}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"prices2":[22,3.5,3.57,8.965,2.5463,9.99]}"#)).to(beTrue())
                        expect(jsonString?.contains(#"{"rewardsPrices":[69.99,77.99,79.99,89.99,99.99]}"#)).to(beTrue())
                    }

                    it("should return data with a valid JSON structure") {
                        verifyStructure(internalSerialization: true)
                    }
                }

                func verifyValues(from jsonString: String?) {
                    expect(jsonString?.hasPrefix(PayloadConstants.prefix)).to(beTrue())
                    expect(jsonString?.contains(#""key1":"value1""#)).to(beTrue())
                    expect(jsonString?.contains(#""key2":"value2""#)).to(beTrue())
                    expect(jsonString?.contains(#""key3":"value3""#)).to(beTrue())
                    expect(jsonString?.contains(#""key6":"value6""#)).to(beTrue())
                    expect(jsonString?.contains(#""key7":"value7""#)).to(beTrue())
                    expect(jsonString?.contains(#"{"flag1":true}"#)).to(beTrue())
                    expect(jsonString?.contains(#"{"flag2":false}"#)).to(beTrue())
                    expect(jsonString?.contains(#"{"nullable1":null}"#)).to(beTrue())
                    expect(jsonString?.contains(#"{"nullable2":null}"#)).to(beTrue())
                }

                func verifyStructure(internalSerialization: Bool) {
                    let jsonObject = Data(ratJsonRecords: input, internalSerialization: internalSerialization)?.ratPayload

                    expect(jsonObject).toNot(beNil())
                }
            }
        }
    }
}
