import Testing
import Foundation
@testable import RakutenAnalytics
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif

@Suite("RAT Array Extension")
struct RATArrayExtensionTests {
    @Suite("init")
    struct InitTests {
        @Suite("when the passed in array elements are serialized json dictionaries")
        struct SerializedJsonDictionariesTests {
            @Test("should return an array of the expected json dictionary elements")
            func testShouldReturnExpectedJsonDictionaryElements() throws {
                // swiftlint:disable:next force_try
                let dictionaryData = try! JSONSerialization.data(withJSONObject: ["key": "value"], options: .init(rawValue: 0))
                let dataArray = [dictionaryData, dictionaryData]
                let expected = [["key": "value"], ["key": "value"]] as [JsonRecord]
                
                guard let result = [JsonRecord](ratDataRecords: dataArray) else {
                    Issue.record("Failed to create JsonRecord array")
                    return
                }
                
                #expect(result.count == expected.count)
                #expect(result[0]["key"] as? String == expected[0]["key"] as? String)
                #expect(result[1]["key"] as? String == expected[1]["key"] as? String)
            }
        }
        
        @Suite("when the input array elements are not serialized json dictionaries")
        struct NotSerializedJsonDictionariesTests {
            @Test("should return a nil array")
            func testShouldReturnNilArray() {
                let dataArray = ["a", "b"].compactMap({ $0.data(using: .utf8) as Data? })
                let result = [JsonRecord](ratDataRecords: dataArray)
                #expect(result == nil)
            }
        }
    }
}

@Suite("RAT Data Extension")
struct RATDataExtensionTests {
    static let jsonData: Data? = {
        guard let url = BundleHelper.ratJsonUrl else { return nil }
        return try? String(contentsOf: url, encoding: .utf8).data(using: .utf8)
    }()
    
    static let input: [JsonRecord]? = {
        guard let jsonData = jsonData else { return nil }
        return try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [JsonRecord]
    }()
    
    static let testInput: [JsonRecord] = [
        ["key1": "value1", "key2": "value2"],
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
        ["rewardsPrices": [69.99, 77.99, 79.99, 89.99, 99.99]]
    ] as [JsonRecord]
    
    @Suite("init")
    struct InitTests {
        @Suite("when the internal serializer serializes a big amount of data")
        struct BigAmountOfDataTests {
            @Test("should not crash")
            func testShouldNotCrash() {
                guard let input = RATDataExtensionTests.input else {
                    Issue.record("Failed to load test JSON data")
                    return
                }
                let array = Array(repeating: input, count: 1000).flatMap { $0 }
                let data = Data(ratJsonRecords: array, internalSerialization: true)
                #expect(data != nil)
            }
        }
        
        @Suite("when the input array elements are dictionaries")
        struct DictionariesTests {
            @Suite("when internalSerialization is false")
            struct InternalSerializationFalseTests {
                @Test("should return valid data")
                func testShouldReturnValidData() {
                    let data = Data(ratJsonRecords: RATDataExtensionTests.testInput, internalSerialization: false)
                    #expect(data != nil)
                }
                
                @Test("should return data with correct values except for Float numbers")
                func testShouldReturnDataWithCorrectValuesExceptFloatNumbers() {
                    guard let data = Data(ratJsonRecords: RATDataExtensionTests.testInput, internalSerialization: false) else {
                        Issue.record("Data creation failed")
                        return
                    }
                    let jsonString = String(data: data, encoding: .utf8)
                    DictionariesTests.verifyValues(from: jsonString)
                    #expect(jsonString?.contains(#"{"price1":3.57}"#) == false)
                }
                
                @Test("should return data with a valid JSON structure")
                func testShouldReturnDataWithValidJsonStructure() {
                    DictionariesTests.verifyStructure(internalSerialization: false)
                }
            }
            
            @Suite("when internalSerialization is true")
            struct InternalSerializationTrueTests {
                @Test("should return valid data")
                func testShouldReturnValidData() {
                    let data = Data(ratJsonRecords: RATDataExtensionTests.testInput, internalSerialization: true)
                    #expect(data != nil)
                }
                
                @Test("should return data with correct values")
                func testShouldReturnDataWithCorrectValues() {
                    guard let data = Data(ratJsonRecords: RATDataExtensionTests.testInput, internalSerialization: true) else {
                        Issue.record("Data creation failed")
                        return
                    }
                    let jsonString = String(data: data, encoding: .utf8)
                    DictionariesTests.verifyValues(from: jsonString)
                    // swiftlint:disable:next line_length
                    #expect(jsonString?.contains(#"{"any1":[null,null,null,"domain.com",58,34.56,true,false,[0,1,2,3,4,5],{"user":{"name":"john"}}]}"#) == true)
                    
                    // Empty
                    #expect(jsonString?.contains(#"{"emptyArray":[]}"#) == true)
                    #expect(jsonString?.contains(#"{"emptyDict":{}}"#) == true)
                    
                    // Location
                    #expect(jsonString?.contains(#"{"latitude":35.59731937917094}"#) == true)
                    #expect(jsonString?.contains(#"{"longitude":139.62372840340936}"#) == true)
                    
                    // Prices
                    #expect(jsonString?.contains(#"{"priceInt1":5}"#) == true)
                    #expect(jsonString?.contains(#"{"priceInt2":50}"#) == true)
                    #expect(jsonString?.contains(#"{"priceInt3":500}"#) == true)
                    #expect(jsonString?.contains(#"{"priceInt4":5000}"#) == true)
                    #expect(jsonString?.contains(#"{"priceInt5":50000}"#) == true)
                    #expect(jsonString?.contains(#"{"price1":5}"#) == true)
                    #expect(jsonString?.contains(#"{"price2":5.1}"#) == true)
                    #expect(jsonString?.contains(#"{"price3":3.57}"#) == true)
                    #expect(jsonString?.contains(#"{"price4":9.99}"#) == true)
                    #expect(jsonString?.contains(#"{"price5":69.99}"#) == true)
                    // swiftlint:disable:next line_length
                    #expect(jsonString?.contains(#"{"prices1":[null,null,null,41.65,59.5,22,23.35,9.99,21.99,21.41,17.87,19.99,49.99,41.65,24.99]}"#) == true)
                    #expect(jsonString?.contains(#"{"prices2":[22,3.5,3.57,8.965,2.5463,9.99]}"#) == true)
                    #expect(jsonString?.contains(#"{"rewardsPrices":[69.99,77.99,79.99,89.99,99.99]}"#) == true)
                }
                
                @Test("should return data with a valid JSON structure")
                func testShouldReturnDataWithValidJsonStructure() {
                    DictionariesTests.verifyStructure(internalSerialization: true)
                }
            }
            
            static func verifyValues(from jsonString: String?) {
                #expect(jsonString?.hasPrefix(PayloadConstants.prefix) == true)
                #expect(jsonString?.contains(#""key1":"value1""#) == true)
                #expect(jsonString?.contains(#""key2":"value2""#) == true)
                #expect(jsonString?.contains(#""key3":"value3""#) == true)
                #expect(jsonString?.contains(#""key6":"value6""#) == true)
                #expect(jsonString?.contains(#""key7":"value7""#) == true)
                #expect(jsonString?.contains(#"{"flag1":true}"#) == true)
                #expect(jsonString?.contains(#"{"flag2":false}"#) == true)
                #expect(jsonString?.contains(#"{"nullable1":null}"#) == true)
                #expect(jsonString?.contains(#"{"nullable2":null}"#) == true)
            }
            
            static func verifyStructure(internalSerialization: Bool) {
                let jsonObject = Data(ratJsonRecords: RATDataExtensionTests.testInput, internalSerialization: internalSerialization)?.ratPayload
                #expect(jsonObject != nil)
            }
        }
    }
}
