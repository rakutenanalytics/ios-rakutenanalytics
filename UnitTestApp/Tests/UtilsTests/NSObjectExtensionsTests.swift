import Foundation
import Testing
import class UIKit.UIWindow
@testable import RakutenAnalytics

@Suite("NSObjectExtensionsTests")
struct NSObjectExtensionsTests {
    
    @Suite("isKind(of:) instance method")
    struct IsKindOfTests {
        let object = NSArray()
        
        @Test("will return true if class name matches")
        func testReturnsTrueForMatchingClassName() {
            #expect(object.isKind(of: "NSArray") == true)
        }
        
        @Test("will return false if class name does not match")
        func testReturnsFalseForNonMatchingClassName() {
            #expect(object.isKind(of: "NSSet") == false)
        }
        
        @Test("will return false for subclass type")
        func testReturnsFalseForSubclassType() {
            #expect(object.isKind(of: "NSMutableArray") == false)
        }
        
        @Test("will return true if class name matches base type")
        func testReturnsTrueForBaseType() {
            #expect(object.isKind(of: "NSObject") == true)
        }
    }
    
    @Suite("isAppleClass() instance method")
    struct IsAppleClassTests {
        @Test("will return true for apple class instance")
        func testReturnsTrueForAppleClass() {
            let object = NSArray()
            #expect(object.isAppleClass() == true)
        }
        
        @Test("will return false for non apple class instance")
        func testReturnsFalseForNonAppleClass() {
            let object = CustomClass()
            #expect(object.isAppleClass() == false)
        }
    }
    
    @Suite("isApplePrivateClass() instance method")
    struct IsApplePrivateClassTests {
        @Test("will return false for public apple class instance")
        func testReturnsFalseForPublicAppleClass() {
            let object = NSObject()
            #expect(object.isApplePrivateClass() == false)
        }
        
        @Test("will return false for non apple class instance")
        func testReturnsFalseForNonAppleClass() {
            let object = CustomClass()
            #expect(object.isApplePrivateClass() == false)
        }
        
        @Test("will return false for non apple class instance that starts with _")
        func testReturnsFalseForPrivateNonAppleClass() {
            let object = _PrivateCustomClass()
            #expect(object.isApplePrivateClass() == false)
        }
        
        #if os(iOS)
        @Test("will return true for private apple class instance")
        @MainActor
        func testReturnsTrueForPrivateAppleClass() {
            let window = UIWindow()
            // swiftlint:disable:next force_cast
            let object = window.value(forKey: "_systemGestureGateForGestures") as! NSObject // _UISystemGestureGateGestureRecognizer
            #expect(object.isApplePrivateClass() == true)
        }
        #endif
    }
    
    @Suite("isNullableObjectEqual() class method")
    struct IsNullableObjectEqualTests {
        @Test("will return true for two null objects")
        func testReturnsTrueForTwoNullObjects() {
            #expect(NSObject.isNullableObjectEqual(nil, to: nil) == true)
        }
        
        @Test("will return true for two identical objects")
        func testReturnsTrueForIdenticalObjects() {
            let object = NSObject()
            #expect(NSObject.isNullableObjectEqual(object, to: object) == true)
        }
        
        @Test("will return true for two equal objects")
        func testReturnsTrueForEqualObjects() {
            let object1 = [1] as NSArray
            let object2 = [1] as NSArray
            #expect(NSObject.isNullableObjectEqual(object1, to: object2) == true)
        }
        
        @Test("will return false for one null objects")
        func testReturnsFalseForOneNullObject() {
            #expect(NSObject.isNullableObjectEqual(nil, to: NSObject()) == false)
            #expect(NSObject.isNullableObjectEqual(NSObject(), to: nil) == false)
        }
        
        @Test("will return false if one object is a subclass of the other")
        func testReturnsFalseForSubclassObjects() {
            let object1 = NSObject()
            let object2 = CustomClass()
            #expect(NSObject.isNullableObjectEqual(object1, to: object2) == false)
        }
    }
}

private class CustomClass: NSObject { }
private class _PrivateCustomClass: NSObject { }
