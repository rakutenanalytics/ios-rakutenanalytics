import Foundation

/// Coordinates GDPR local data erasure across SDK-owned storage and in-memory state.
/// Does not send analytics events.
final class DataEraserCoordinator {
    private let erasables: [DataErasable]
    private let clearingState = ClearingState()

    init(erasables: [DataErasable]) {
        self.erasables = erasables
    }

    func clearData() async throws {
        try clearingState.beginClearing()
        defer { clearingState.endClearing() }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for erasable in erasables {
                group.addTask {
                    try await erasable.clearData()
                }
            }
            try await group.waitForAll()
        }
    }
}

private final class ClearingState: @unchecked Sendable {
    private let lock = NSLock()
    private var isClearingData = false

    func beginClearing() throws {
        try lock.withLock {
            guard !isClearingData else {
                throw ClearDataError.alreadyRunning
            }
            isClearingData = true
        }
    }

    func endClearing() {
        lock.withLock {
            isClearingData = false
        }
    }
}
