import Foundation

final class ViewableImpressionRefreshCoordinator {
    private let lock = NSLock()
    private var inFlight: Task<[String: Any]?, Never>?

    @MainActor
    func refresh(
        evaluate: @escaping () -> ViewableImpressionRefreshResult
    ) async -> [String: Any]? {
        cancelInFlightTask()

        let task = Task { @MainActor in
            let result = evaluate()
            return await ViewableImpressionRefreshScheduler.deliver(result: result)
        }
        lock.withLock {
            inFlight = task
        }

        return await task.value
    }

    func cancel() {
        cancelInFlightTask()
    }

    private func cancelInFlightTask() {
        lock.withLock {
            inFlight?.cancel()
            inFlight = nil
        }
    }
}
