import Foundation

@MainActor
final class GeoUserActionRequestCoordinator {
    private var continuation: CheckedContinuation<LocationModel, Error>?
    private(set) var actionParameters: GeoActionParameters?

    func begin(
        actionParameters: GeoActionParameters?,
        requestUpdate: () -> Void
    ) async throws -> LocationModel {
        cancel(with: CancellationError())

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.actionParameters = actionParameters
                self.continuation = continuation
                requestUpdate()
            }
        } onCancel: {
            Task { @MainActor in
                self.cancel(with: CancellationError())
            }
        }
    }

    func complete(with location: LocationModel) {
        finish(with: .success(location))
    }

    func fail(with error: Error) {
        finish(with: .failure(error))
    }

    func cancel(with error: Error = CancellationError()) {
        finish(with: .failure(error))
    }

    private func finish(with result: Result<LocationModel, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        actionParameters = nil
        switch result {
        case .success(let location):
            continuation.resume(returning: location)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}
