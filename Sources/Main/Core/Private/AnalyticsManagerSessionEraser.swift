import Foundation

/// Clears AnalyticsManager-owned session and auxiliary persisted state.
final class AnalyticsManagerSessionEraser: DataErasable {
    private weak var delegate: SessionDataDelegating?

    init(delegate: SessionDataDelegating) {
        self.delegate = delegate
    }

    func clearData() async throws {
        delegate?.clearSessionData()
    }
}
