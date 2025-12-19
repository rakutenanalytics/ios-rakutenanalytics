import Testing
@testable import RakutenAnalytics

@Suite("GeoActionParameters")
struct GeoActionParametersTests {
    
    @Test("should contain non-nil values in its stored properties")
    func testNonNilProperties() {
        let actionParameters = GeoActionParameters(
            actionType: "test-actionType",
            actionLog: "test-actionLog",
            actionId: "test-actionId",
            actionDuration: "test-actionDuration",
            additionalLog: "test-additionalLog")
        
        #expect(actionParameters.actionType != nil)
        #expect(actionParameters.actionLog != nil)
        #expect(actionParameters.actionId != nil)
        #expect(actionParameters.actionDuration != nil)
        #expect(actionParameters.additionalLog != nil)
        
        #expect(actionParameters.actionType == "test-actionType")
        #expect(actionParameters.actionLog == "test-actionLog")
        #expect(actionParameters.actionId == "test-actionId")
        #expect(actionParameters.actionDuration == "test-actionDuration")
        #expect(actionParameters.additionalLog == "test-additionalLog")
    }
    
    @Test("should contain nil values in its stored properties")
    func testNilProperties() {
        let actionParameters = GeoActionParameters(
            actionType: nil,
            actionLog: nil,
            actionId: nil,
            actionDuration: nil,
            additionalLog: nil)
        
        #expect(actionParameters.actionType == nil)
        #expect(actionParameters.actionLog == nil)
        #expect(actionParameters.actionId == nil)
        #expect(actionParameters.actionDuration == nil)
        #expect(actionParameters.additionalLog == nil)
    }
    
    @Test("should contain nil when stored properties are not set on GeoActionParameters")
    func testDefaultNilProperties() {
        let geoActionParameters = GeoActionParameters()
        #expect(geoActionParameters.actionType == nil)
        #expect(geoActionParameters.actionLog == nil)
        #expect(geoActionParameters.actionId == nil)
        #expect(geoActionParameters.actionDuration == nil)
        #expect(geoActionParameters.additionalLog == nil)
    }
    
    @Test("should contain nil when values are not passed in its stored properties")
    func testPartialNilProperties() {
        let actionParameters = GeoActionParameters(actionLog: "actionLog", actionId: "123")
        #expect(actionParameters.actionType == nil)
        #expect(actionParameters.actionDuration == nil)
    }
    
    @Test("should contain non-nil values when its stored properties contains values")
    func testPartialNonNilProperties() {
        let actionParameters = GeoActionParameters(actionLog: "actionLog", actionId: "123")
        #expect(actionParameters.actionLog == "actionLog")
        #expect(actionParameters.actionId == "123")
    }
}
