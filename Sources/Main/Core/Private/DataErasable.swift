import Foundation

/// Erases locally persisted analytics data owned by a single SDK component.
protocol DataErasable: AnyObject {
    func clearData() async throws
}

extension DataErasable {
    func clearData(completion: @escaping () -> Void) {
        Task {
            try? await clearData()
            completion()
        }
    }
}
