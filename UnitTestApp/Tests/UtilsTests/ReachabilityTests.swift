import Foundation
import Testing
import struct SystemConfiguration.SCNetworkReachabilityFlags
@testable import RakutenAnalytics

@Suite("Reachability")
struct ReachabilityTests {
    
    @Suite("init")
    struct InitTests {
        @Test("will create an instance of Reachability")
        func testCreatesInstance() {
            let instance = Reachability()
            // Verify instance was created successfully by checking it's not nil
            // Since Reachability() returns non-optional, if initialization succeeds, instance exists
            _ = instance
        }
    }
    
    @Suite("connection available")
    struct ConnectionAvailableTests {
        func createReachability() -> Reachability {
            return Reachability()
        }
        
        fileprivate func createObserver() -> Observer {
            return Observer()
        }
        
        @Test("will return proper flags when connection is available")
        func testReturnsProperFlags() {
            let reachability = createReachability()
            let observer = createObserver()
            defer {
                reachability.removeObserver(observer)
            }
            
            // Simulate a reachable network
            reachability.setFlagsForTesting(.reachable)
            #expect(reachability.flags == [.reachable])
            #expect(reachability.flags?.description == "-R")
        }
        
        @Test("will return proper connection status for Wi-Fi")
        func testReturnsWiFiConnectionStatus() {
            let reachability = createReachability()
            let observer = createObserver()
            defer {
                reachability.removeObserver(observer)
            }
            
            // Simulate a Wi-Fi connection
            reachability.setFlagsForTesting(.reachable)
            #expect(reachability.connection == .wifi)
        }
        
        @Test("will return proper connection status for cellular")
        func testReturnsCellularConnectionStatus() async throws {
            let reachability = createReachability()
            let observer = createObserver()
            defer {
                reachability.removeObserver(observer)
            }
            
            // Simulate a cellular connection
            reachability.setFlagsForTesting([.reachable, .isWWAN])
            #if targetEnvironment(simulator)
            try await TestingHelpers.eventually(timeout: 2.0) {
                reachability.connection == .wifi
            }
            #expect(reachability.connection == .wifi)
            #else
            #expect(reachability.connection == .cellular)
            #endif
        }
        
        @Test("will return unavailable connection status when not reachable")
        func testReturnsUnavailableConnectionStatus() {
            let reachability = createReachability()
            let observer = createObserver()
            defer {
                reachability.removeObserver(observer)
            }
            
            // Simulate no network connection
            reachability.setFlagsForTesting([])
            #expect(reachability.connection == .unavailable)
        }
        
        @Test("will notify observers when connection changes")
        func testNotifiesObserversOnConnectionChange() async throws {
            let reachability = createReachability()
            let observer = createObserver()
            defer {
                reachability.removeObserver(observer)
            }
            
            reachability.addObserver(observer)
            
            // Simulate a Wi-Fi connection
            reachability.setFlagsForTesting(.reachable)
            try await TestingHelpers.eventually(timeout: 2.0) {
                observer.currentStatus == .wifi
            }
            #expect(observer.currentStatus == .wifi)
            
            // Simulate a cellular connection
            reachability.setFlagsForTesting([.reachable, .isWWAN])
            #if targetEnvironment(simulator)
            try await TestingHelpers.eventually(timeout: 2.0) {
                observer.currentStatus == .wifi
            }
            #expect(observer.currentStatus == .wifi)
            #else
            try await TestingHelpers.eventually(timeout: 2.0) {
                observer.currentStatus == .cellular
            }
            #expect(observer.currentStatus == .cellular)
            #endif
            
            // Simulate no network connection
            reachability.setFlagsForTesting([])
            try await TestingHelpers.eventually(timeout: 2.0) {
                observer.currentStatus == .unavailable
            }
            #expect(observer.currentStatus == .unavailable)
        }
    }
}

private class Observer: ReachabilityObserver {
    var currentStatus: Reachability.Connection?
    
    func reachabilityChanged(_ reachability: ReachabilityType) {
        currentStatus = reachability.connection
    }
}
