import Foundation

struct ViewableImpressionRefreshScheduler {
    @MainActor
    static func deliver(result: ViewableImpressionRefreshResult) async -> [String: Any]? {
        if !result.eventData.isEmpty {
            return result.eventParameters
        }

        if let delay = result.refreshAfterDelay,
           let refreshAfterDwell = result.refreshAfterDwell {
            let nanoseconds = UInt64(delay * 1_000_000_000)
            do {
                try await Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return nil
            }
            let followUp = refreshAfterDwell()
            return await deliver(result: followUp)
        }

        return result.eventParameters
    }
}
