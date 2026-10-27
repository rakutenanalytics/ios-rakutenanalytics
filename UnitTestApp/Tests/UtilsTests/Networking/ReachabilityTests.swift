import Foundation
import Testing
import struct SystemConfiguration.SCNetworkReachabilityFlags
#if canImport(RAnalyticsTestHelpers)
import RAnalyticsTestHelpers
#endif
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

        @Test("will return proper flags when connection is available")
        func testReturnsProperFlags() {
            let reachability = createReachability()

            // Simulate a reachable network
            reachability.setFlagsForTesting(.reachable)
            #expect(reachability.flags == [.reachable])
            #expect(reachability.flags?.description == "-R")
        }

        @Test("will return proper connection status for Wi-Fi")
        func testReturnsWiFiConnectionStatus() {
            let reachability = createReachability()

            // Simulate a Wi-Fi connection
            reachability.setFlagsForTesting(.reachable)
            #expect(reachability.connection == .wifi)
        }

        @Test("will return proper connection status for cellular")
        func testReturnsCellularConnectionStatus() async throws {
            let reachability = createReachability()

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

            // Simulate no network connection
            reachability.setFlagsForTesting([])
            #expect(reachability.connection == .unavailable)
        }
    }

    @Suite("connectionUpdates")
    struct ConnectionUpdatesTests {
        @Test("yields initial connection and subsequent flag changes")
        func testYieldsConnectionUpdates() async throws {
            let reachability = Reachability()

            let streamTask = Task {
                var connections: [Reachability.Connection] = []
                for await connection in reachability.connectionUpdates {
                    connections.append(connection)
                    if connections.count >= 2 {
                        return connections
                    }
                }
                return connections
            }

            try await Task.sleep(nanoseconds: 100_000_000)
            reachability.setFlagsForTesting(.reachable)

            let connections = await streamTask.value
            #expect(connections.first == .unavailable)
            #expect(connections.last == .wifi)
        }

        @Test("yields unavailable when connection is lost")
        func testYieldsConnectionLoss() async throws {
            let reachability = Reachability()
            // Stop NWPathMonitor so only explicit flag changes drive the stream in this test.
            reachability.setFlagsForTesting([])

            let streamTask = Task {
                var connections: [Reachability.Connection] = []
                for await connection in reachability.connectionUpdates {
                    connections.append(connection)
                    if connections.last == .unavailable, connections.contains(.wifi) {
                        return connections
                    }
                }
                return connections
            }

            try await Task.sleep(nanoseconds: 50_000_000)
            reachability.setFlagsForTesting(.reachable)
            reachability.setFlagsForTesting([])

            let connections = await streamTask.value
            #expect(connections.contains(.wifi))
            #expect(connections.last == .unavailable)
        }
    }
}
