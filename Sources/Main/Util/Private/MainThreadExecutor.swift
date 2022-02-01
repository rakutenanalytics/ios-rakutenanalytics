import Foundation

/// MainThreadExecutor is a helper to run closures on the main thread.
struct MainThreadExecutor<T> {
    /// Executes a closure on the main thread
    ///
    /// - Parameter completion: The completion closure to execute.
    /// - Returns: a result of type `T`
    static func run(completion: () -> (T)) -> T {
        // Note: Try running DispatchQueue.main.sync from the main queue and the app will freeze
        // because the calling queue will wait until the dispatched block is over
        // but it won't be even able to start (because the queue is stopped and waiting)
        // So it is needed to check if the current thread is the main thread here.
        if Thread.isMainThread {
            return completion()
        }
        return DispatchQueue.main.sync { completion() }
    }
}
