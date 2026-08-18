import Foundation

/// Helper functions for Testing framework, similar to Quick/Nimble's `toEventually` and `performAsyncTest`
public enum TestingHelpers {
    
    /// Polls until a condition is met, similar to `toEventually` in Quick/Nimble
    /// - Parameters:
    ///   - timeout: Maximum time to wait for the condition (default: 2.0 seconds)
    ///   - condition: Closure that returns true when the condition is met
    /// - Throws: `TestError.conditionNotMet` if condition is not met within timeout
    public static func eventually(timeout: TimeInterval = 2.0, condition: @escaping () -> Bool) async throws {
        let startNs = DispatchTime.now().uptimeNanoseconds
        let timeoutNs = UInt64(timeout * 1_000_000_000)
        let pollIntervalNs: UInt64 = 50_000_000 // 0.05 seconds
        let deadlineNs = startNs &+ timeoutNs
        
        while DispatchTime.now().uptimeNanoseconds < deadlineNs {
            // Yield to allow other tasks/queues to make progress.
            await Task.yield()
            if condition() { return }
            try await Task.sleep(nanoseconds: pollIntervalNs)
        }
        
        if !condition() { throw TestError.conditionNotMet }
    }
    
    /// Polls until a condition is met on main actor, allowing run loop events to process
    /// Similar to `toEventually` in Quick/Nimble, but ensures run loop processes timer events
    /// - Parameters:
    ///   - timeout: Maximum time to wait for the condition (default: 2.0 seconds)
    ///   - condition: Closure that returns true when the condition is met
    /// - Throws: `TestError.conditionNotMet` if condition is not met within timeout
    @MainActor
    public static func eventuallyOnMain(timeout: TimeInterval = 2.0, condition: @escaping () -> Bool) async throws {
        let startNs = DispatchTime.now().uptimeNanoseconds
        let timeoutNs = UInt64(timeout * 1_000_000_000)
        let pollIntervalNs: UInt64 = 100_000_000 // 0.1 seconds (leave room for main runloop work)
        let deadlineNs = startNs &+ timeoutNs
        
        while DispatchTime.now().uptimeNanoseconds < deadlineNs {
            await Task.yield()
            if condition() { return }
            try await Task.sleep(nanoseconds: pollIntervalNs)
        }
        
        if !condition() { throw TestError.conditionNotMet }
    }
    
    /// Polls until an async condition is met
    /// - Parameters:
    ///   - timeout: Maximum time to wait for the condition (default: 2.0 seconds)
    ///   - condition: Async closure that returns true when the condition is met
    /// - Throws: `TestError.conditionNotMet` if condition is not met within timeout
    public static func eventuallyAsync(timeout: TimeInterval = 2.0, condition: @escaping () async -> Bool) async throws {
        let startNs = DispatchTime.now().uptimeNanoseconds
        let timeoutNs = UInt64(timeout * 1_000_000_000)
        let pollIntervalNs: UInt64 = 100_000_000 // 0.1 seconds
        let deadlineNs = startNs &+ timeoutNs
        
        while DispatchTime.now().uptimeNanoseconds < deadlineNs {
            await Task.yield()
            if await condition() { return }
            try await Task.sleep(nanoseconds: pollIntervalNs)
        }
        
        if !(await condition()) { throw TestError.conditionNotMet }
    }
    
    /// Performs an async test similar to `QuickSpec.performAsyncTest`
    /// Waits for a specified timeout period, then executes the expectation closure
    /// - Parameters:
    ///   - timeForExecution: Expected time for async work to complete (used for documentation/logging)
    ///   - timeout: Time to wait before executing the expectation closure
    ///   - expectation: Closure containing test assertions to execute after the wait period
    /// - Note: This is equivalent to Quick/Nimble's `performAsyncTest`. The expectation is executed
    ///   after `timeout` seconds, allowing async work (expected to complete in `timeForExecution`) to finish.
    public static func performAsyncTest(timeForExecution: TimeInterval, timeout: TimeInterval, expectation: @escaping () async throws -> Void
    ) async throws {
        let timeoutNanoseconds = UInt64(timeout * 1_000_000_000)
        try await Task.sleep(nanoseconds: timeoutNanoseconds)
        try await expectation()
    }
    
    /// Performs an async test on the main actor, similar to `QuickSpec.performAsyncTest`
    /// Waits for a specified timeout period, then executes the expectation closure on the main thread
    /// - Parameters:
    ///   - timeForExecution: Expected time for async work to complete (used for documentation/logging)
    ///   - timeout: Time to wait before executing the expectation closure
    ///   - expectation: Closure containing test assertions to execute after the wait period
    /// - Note: This ensures the expectation runs on the main thread, useful for UI-related tests.
    ///   The expectation is executed after `timeout` seconds, allowing async work to finish.
    @MainActor
    public static func performAsyncTestOnMain(timeForExecution: TimeInterval, timeout: TimeInterval, expectation: @escaping () async throws -> Void) async throws {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            await Task.yield()
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        try await expectation()
    }
    
    /// Error thrown when a condition is not met within the timeout period
    public enum TestError: Error {
        case conditionNotMet
    }
}

