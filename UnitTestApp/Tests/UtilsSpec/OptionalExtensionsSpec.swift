import Foundation
import Testing
import UIKit
import CoreLocation.CLLocation
@testable import RakutenAnalytics

@Suite("Optional+NSObject Extensions")
struct OptionalNSObjectExtensionsSpec {
    
    @Suite("isKind(of:) instance method")
    struct IsKindOfTests {
        let object: NSArray? = NSArray()
        
        @Test("will return true if class name matches")
        func testReturnsTrueForMatchingClassName() {
            #expect(object.isKind(of: "NSArray") == true)
        }
        
        @Test("will return false if class name does not match")
        func testReturnsFalseForNonMatchingClassName() {
            #expect(object.isKind(of: "NSSet") == false)
        }
        
        @Test("will return true if class name matches base type")
        func testReturnsTrueForBaseType() {
            #expect(object.isKind(of: "NSObject") == true)
        }
        
        @Test("will return false for subclass type")
        func testReturnsFalseForSubclassType() {
            #expect(object.isKind(of: "NSMutableArray") == false)
        }
        
        @Test("will return false if object is nil")
        func testReturnsFalseIfObjectIsNil() {
            let object: NSArray? = nil
            #expect(object.isKind(of: "NSArray") == false)
        }
    }
    
    #if os(iOS)
    @Suite("isMember(of:) instance method")
    struct IsMemberOfTests {
        let object: UIView? = UIView()
        
        @Test("will return true if class type matches")
        func testReturnsTrueForMatchingClassType() {
            #expect(object.isMember(of: UIView.self) == true)
        }
        
        @Test("will return false if class does not match")
        func testReturnsFalseForNonMatchingClass() {
            #expect(object.isMember(of: NSArray.self) == false)
        }
        
        @Test("will return false for subclass type")
        func testReturnsFalseForSubclassType() {
            #expect(object.isMember(of: UIButton.self) == false)
        }
        
        @Test("will return false for superclass")
        func testReturnsFalseForSuperclass() {
            #expect(object.isMember(of: NSObject.self) == false)
        }
        
        @Test("will return false if object is nil")
        func testReturnsFalseIfObjectIsNil() {
            let object: UIView? = nil
            #expect(object.isMember(of: UIView.self) == false)
        }
    }
    #endif
    
    @Suite("isAppleClass() instance method")
    struct IsAppleClassTests {
        @Test("will return true for apple class instance")
        func testReturnsTrueForAppleClass() {
            let object: NSArray? = NSArray()
            #expect(object.isAppleClass() == true)
        }
        
        @Test("will return false for non apple class instance")
        func testReturnsFalseForNonAppleClass() {
            let object: CustomClass? = CustomClass()
            #expect(object.isAppleClass() == false)
        }
        
        @Test("will return false if object is nil")
        func testReturnsFalseIfObjectIsNil() {
            let object: NSArray? = nil
            #expect(object.isAppleClass() == false)
        }
    }
    
    @Suite("isApplePrivateClass() instance method")
    struct IsApplePrivateClassTests {
        @Test("will return false for public apple class instance")
        func testReturnsFalseForPublicAppleClass() {
            let object: NSObject? = NSObject()
            #expect(object.isApplePrivateClass() == false)
        }
        
        @Test("will return false for non apple class instance")
        func testReturnsFalseForNonAppleClass() {
            let object: CustomClass? = CustomClass()
            #expect(object.isApplePrivateClass() == false)
        }
        
        @Test("will return false for non apple class instance that starts with _")
        func testReturnsFalseForPrivateNonAppleClass() {
            let object: _PrivateCustomClass? = _PrivateCustomClass()
            #expect(object.isApplePrivateClass() == false)
        }
        
        #if os(iOS)
        @Test("will return true for private apple class instance")
        @MainActor
        func testReturnsTrueForPrivateAppleClass() {
            let window = UIWindow()
            let object = window.value(forKey: "_systemGestureGateForGestures") as? NSObject // _UISystemGestureGateGestureRecognizer
            #expect(object != nil)
            #expect(object.isApplePrivateClass() == true)
        }
        
        @Test("will return false if object is nil")
        @MainActor
        func testReturnsFalseIfObjectIsNil() {
            let window = UIWindow()
            var object = window.value(forKey: "_systemGestureGateForGestures") as? NSObject
            object = nil
            #expect(object.isApplePrivateClass() == false)
        }
        #endif
    }
    
    @Suite("safeHashValue instance variable")
    struct SafeHashValueTests {
        @Test("will return expected hashValue")
        func testReturnsExpectedHashValue() {
            let object: CustomClass? = CustomClass()
            #expect(object.safeHashValue == 100)
        }
        
        @Test("will return 0 if object is nil")
        func testReturnsZeroIfObjectIsNil() {
            let object: CustomClass? = nil
            #expect(object.safeHashValue == 0)
        }
    }
}

@Suite("Optional+String Extensions")
struct OptionalStringExtensionsSpec {
    @Suite("safeHashValue instance variable")
    struct SafeHashValueTests {
        @Test("will return expected hashValue for a non-empty string")
        func testReturnsExpectedHashValueForNonEmptyString() {
            let object: String? = "hello"
            #expect(object.safeHashValue == "hello".hashValue)
        }
        
        @Test("will return expected hashValue for an empty string")
        func testReturnsExpectedHashValueForEmptyString() {
            let object: String? = ""
            #expect(object.safeHashValue == "".hashValue)
        }
        
        @Test("will return 0 if object is nil")
        func testReturnsZeroIfObjectIsNil() {
            let object: String? = nil
            #expect(object.safeHashValue == 0)
        }
    }
    
    @Suite("isEmpty instance variable")
    struct IsEmptyTests {
        @Test("will return false if Wrapped is a non-empty String")
        func testReturnsFalseForNonEmptyString() {
            let object: String? = "hello"
            #expect(object.isEmpty == false)
        }
        
        @Test("will return true if Wrapped is an empty String")
        func testReturnsTrueForEmptyString() {
            let object: String? = ""
            #expect(object.isEmpty == true)
        }
        
        @Test("will return true if object is nil")
        func testReturnsTrueIfObjectIsNil() {
            let object: String? = nil
            #expect(object.isEmpty == true)
        }
    }
    
    @Suite("combine(with:) instance method")
    struct CombineTests {
        @Test("will return combined string if both strings are non-nil")
        func testReturnsCombinedStringForBothNonNil() {
            let object: String? = "hello"
            let other: String? = " world"
            #expect(object.combine(with: other) == "hello world")
        }
        
        @Test("will return the first string if the second string is nil")
        func testReturnsFirstStringIfSecondIsNil() {
            let object: String? = "hello"
            let other: String? = nil
            #expect(object.combine(with: other) == "hello")
        }
        
        @Test("will return the second string if the first string is nil")
        func testReturnsSecondStringIfFirstIsNil() {
            let object: String? = nil
            let other: String? = "world"
            #expect(object.combine(with: other) == "world")
        }
        
        @Test("will return an empty string if both strings are nil")
        func testReturnsEmptyStringIfBothNil() {
            let object: String? = nil
            let other: String? = nil
            #expect(object.combine(with: other) == "")
        }
        
        @Test("will return the first string if the second string is empty")
        func testReturnsFirstStringIfSecondIsEmpty() {
            let object: String? = "hello"
            let other: String? = ""
            #expect(object.combine(with: other) == "hello")
        }
        
        @Test("will return the second string if the first string is empty")
        func testReturnsSecondStringIfFirstIsEmpty() {
            let object: String? = ""
            let other: String? = "world"
            #expect(object.combine(with: other) == "world")
        }
        
        @Test("will return an empty string if both strings are empty")
        func testReturnsEmptyStringIfBothEmpty() {
            let object: String? = ""
            let other: String? = ""
            #expect(object.combine(with: other) == "")
        }
    }
}

@Suite("Optional+CLLocation Extensions")
struct OptionalCLLocationExtensionsSpec {
    @Suite("safeHashValue instance variable")
    struct SafeHashValueTests {
        @Test("will return expected hashValue")
        func testReturnsExpectedHashValue() {
            let object: CLLocation? = CLLocation(latitude: 35.6144, longitude: 139.6264)
            #expect(object.safeHashValue == CLLocation(latitude: 35.6144, longitude: 139.6264).description.hashValue)
        }
        
        @Test("will return 0 if object is nil")
        func testReturnsZeroIfObjectIsNil() {
            let object: CLLocation? = nil
            #expect(object.safeHashValue == 0)
        }
    }
}

private class CustomClass: NSObject {
    override var hash: Int { 100 }
}
private class _PrivateCustomClass: NSObject { }
