import Foundation

struct ViewableImpressionRefreshScheduler {
    static func deliver(result: ViewableImpressionRefreshResult,
                        pendingWorkItem: inout DispatchWorkItem?,
                        onResult: @escaping (_ eventParameters: [String: Any]?) -> Void) {
        if !result.eventData.isEmpty || result.refreshAfterDelay == nil {
            pendingWorkItem?.cancel()
            pendingWorkItem = nil
            DispatchQueue.main.async {
                onResult(result.eventParameters)
            }
            return
        }

        guard let delay = result.refreshAfterDelay,
              let refreshAfterDwell = result.refreshAfterDwell else {
            pendingWorkItem?.cancel()
            pendingWorkItem = nil
            DispatchQueue.main.async {
                onResult(result.eventParameters)
            }
            return
        }

        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            let followUp = refreshAfterDwell()
            onResult(followUp.eventParameters)
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}
