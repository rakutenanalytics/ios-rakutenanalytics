import Foundation

enum AppStateOrigin {
    case foreground
    case background
}

protocol SenderScheduleContext: AnyObject {
    func senderMaxUploadInterval() -> TimeInterval
    func senderUploadTimerInterval() -> TimeInterval
    func setSenderUploadTimerInterval(_ interval: TimeInterval)
    var backgroundTimerEnabler: SenderBackgroundTimerEnabler { get }
    func batchingDelayInterval() -> TimeInterval?
    func scheduleElapsedTime(for startTimeKey: String) -> TimeInterval?
    func ensureBackgroundScheduleStartDate(for startTimeKey: String)
    func performInsert(dataBlob: Data) async
    func performFetchAndUpload() async
}

/// Holds schedule task handles for synchronous cancellation from sender `deinit`.
final class SenderScheduleTaskHandles: @unchecked Sendable {
    private let lock = NSLock()
    private var uploadScheduleTask: Task<Void, Never>?
    private var insertChain: Task<Void, Never>?

    func setUploadScheduleTask(_ task: Task<Void, Never>?) {
        lock.lock()
        uploadScheduleTask = task
        lock.unlock()
    }

    func setInsertChain(_ task: Task<Void, Never>?) {
        lock.lock()
        insertChain = task
        lock.unlock()
    }

    func cancelAll() {
        lock.lock()
        uploadScheduleTask?.cancel()
        uploadScheduleTask = nil
        insertChain?.cancel()
        insertChain = nil
        lock.unlock()
    }
}

/// Sync mirror of actor scheduling-idle state for the `isUploadSchedulingIdle` test seam.
final class UploadSchedulingIdleMirror: @unchecked Sendable {
    private let lock = NSLock()
    private var idle = true

    var isIdle: Bool {
        lock.lock()
        defer { lock.unlock() }
        return idle
    }

    func update(uploadSchedulePending: Bool, zeroBatchingDelayUploadInProgress: Bool) {
        lock.lock()
        idle = !uploadSchedulePending && !zeroBatchingDelayUploadInProgress
        lock.unlock()
    }
}

private enum ScheduleCoordinatorConstants {
    static let minUploadInterval = TimeInterval(0.0)
    static let retryInterval = TimeInterval(10.0)
}

/// Owns insert-chain serialisation and upload schedule tasks/flags for `RAnalyticsSender`.
actor SenderScheduleCoordinator {
    private let taskHandles: SenderScheduleTaskHandles
    private let idleMirror: UploadSchedulingIdleMirror

    private var insertChain: Task<Void, Never>?
    private var uploadScheduleTask: Task<Void, Never>?
    private var uploadSchedulePending = false
    private var uploadRequested = false
    private var zeroBatchingDelayUploadInProgress = false

    init(taskHandles: SenderScheduleTaskHandles, idleMirror: UploadSchedulingIdleMirror) {
        self.taskHandles = taskHandles
        self.idleMirror = idleMirror
    }

    nonisolated func cancelAllWork() {
        taskHandles.cancelAll()
    }

    nonisolated var isSchedulingIdle: Bool {
        idleMirror.isIdle
    }

    private func updateIdleMirror() {
        idleMirror.update(
            uploadSchedulePending: uploadSchedulePending,
            zeroBatchingDelayUploadInProgress: zeroBatchingDelayUploadInProgress
        )
    }

    func enqueueInsert(dataBlob: Data, context: SenderScheduleContext) {
        let previous = insertChain
        let task = Task { [weak context] in
            _ = await previous?.value
            guard let context else { return }
            await context.performInsert(dataBlob: dataBlob)
            await self.scheduleUploadOrPerformImmediately(appStateOrigin: .foreground, context: context)
        }
        insertChain = task
        taskHandles.setInsertChain(task)
    }

    func scheduleUploadOrPerformImmediately(appStateOrigin: AppStateOrigin, context: SenderScheduleContext) async {
        performScheduleUploadOrPerformImmediately(appStateOrigin: appStateOrigin, context: context)
    }

    private func performScheduleUploadOrPerformImmediately(appStateOrigin: AppStateOrigin, context: SenderScheduleContext) {
        updateUploadTimerInterval(from: context)

        if context.senderUploadTimerInterval() <= 0, !uploadSchedulePending, !zeroBatchingDelayUploadInProgress {
            zeroBatchingDelayUploadInProgress = true
            updateIdleMirror()
            Task { [weak context] in
                await context?.performFetchAndUpload()
            }
        } else {
            scheduleBackgroundUpload(appStateOrigin: appStateOrigin, context: context)
        }
    }

    private func updateUploadTimerInterval(from context: SenderScheduleContext) {
        guard let delay = context.batchingDelayInterval() else { return }

        if case .enabled(let startTimeKey) = context.backgroundTimerEnabler,
           let elapsedTime = context.scheduleElapsedTime(for: startTimeKey) {
            if elapsedTime <= delay {
                context.setSenderUploadTimerInterval(min(
                    max(ScheduleCoordinatorConstants.minUploadInterval, delay - elapsedTime),
                    context.senderMaxUploadInterval()
                ))
            } else {
                context.setSenderUploadTimerInterval(0)
            }
        } else {
            context.setSenderUploadTimerInterval(min(
                max(ScheduleCoordinatorConstants.minUploadInterval, delay),
                context.senderMaxUploadInterval()
            ))
        }
    }

    func scheduleBackgroundUpload(appStateOrigin: AppStateOrigin, context: SenderScheduleContext) {
        if uploadSchedulePending {
            if case .enabled = context.backgroundTimerEnabler,
               appStateOrigin == .background {
                cancelUploadSchedule()
                createUploadSchedule(context: context)
            } else {
                uploadRequested = true
            }
            return
        }

        if case .enabled(let startTimeKey) = context.backgroundTimerEnabler {
            context.ensureBackgroundScheduleStartDate(for: startTimeKey)
        }

        createUploadSchedule(context: context)
    }

    private func createUploadSchedule(context: SenderScheduleContext) {
        let interval = context.senderUploadTimerInterval() == 0
            ? ScheduleCoordinatorConstants.retryInterval
            : context.senderUploadTimerInterval()

        uploadRequested = false
        uploadSchedulePending = true
        updateIdleMirror()

        let task = Task { [weak context] in
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self.uploadScheduleFired(context: context)
        }
        uploadScheduleTask = task
        taskHandles.setUploadScheduleTask(task)
    }

    private func uploadScheduleFired(context: SenderScheduleContext?) async {
        uploadSchedulePending = false
        updateIdleMirror()
        await context?.performFetchAndUpload()
    }

    private func cancelUploadSchedule() {
        uploadScheduleTask?.cancel()
        uploadScheduleTask = nil
        uploadSchedulePending = false
        updateIdleMirror()
        taskHandles.setUploadScheduleTask(nil)
    }

    func backgroundUploadEnded(context: SenderScheduleContext) async {
        performBackgroundUploadEnded(context: context)
    }

    private func performBackgroundUploadEnded(context: SenderScheduleContext) {
        cancelUploadSchedule()
        zeroBatchingDelayUploadInProgress = false
        updateIdleMirror()

        if uploadRequested {
            scheduleBackgroundUpload(appStateOrigin: .foreground, context: context)
        }
    }

    func markUploadRequested() async {
        uploadRequested = true
    }

    /// Cancels pending insert/upload tasks and resets scheduling flags (e.g. GDPR clear-data).
    func clearPendingScheduling() {
        uploadScheduleTask?.cancel()
        uploadScheduleTask = nil
        insertChain?.cancel()
        insertChain = nil
        taskHandles.cancelAll()
        uploadSchedulePending = false
        uploadRequested = false
        zeroBatchingDelayUploadInProgress = false
        updateIdleMirror()
    }
}
