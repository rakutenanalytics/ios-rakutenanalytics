import Foundation

struct ViewableImpressionRefreshScheduler {
    static func deliver(result: ViewableImpressionRefreshResult,
                        pendingWorkItem: inout DispatchWorkItem?,
                        onResult: @escaping (_ eventParameters: [String: Any]?) -> Void) {
        if !result.eventData.isEmpty {
            pendingWorkItem?.cancel()
            pendingWorkItem = nil
            DispatchQueue.main.async {
                onResult(result.eventParameters)
            }
            return
        }

        if let delay = result.refreshAfterDelay,
           let refreshAfterDwell = result.refreshAfterDwell {
            pendingWorkItem?.cancel()
            let workItem = DispatchWorkItem {
                let followUp = refreshAfterDwell()
                onResult(followUp.eventParameters)
            }
            pendingWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
            return
        }

        DispatchQueue.main.async {
            onResult(result.eventParameters)
        }
    }
}
