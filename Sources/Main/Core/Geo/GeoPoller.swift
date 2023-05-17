import Foundation

protocol PollerRunLoopProtocol {

    func add(timer: Timer)
    func invalidate(timer: Timer)
}

extension RunLoop: PollerRunLoopProtocol {

    func add(timer: Timer) {
        add(timer, forMode: .common)
    }

    func invalidate(timer: Timer) {
        timer.invalidate()
    }
}

internal class GeoPoller {

    private let runLoop: PollerRunLoopProtocol
    private var locationCollectionTimer: Timer?

    init(runLoop: PollerRunLoopProtocol = RunLoop.current) {
        self.runLoop = runLoop
    }

    func pollLocationCollection(delay: TimeInterval, repeats: Bool, action: @escaping () -> Void) {
        guard !isRunning else {
            return
        }
        self.locationCollectionTimer = Timer(timeInterval: delay, repeats: repeats, block: { (_) in
            action()
        })

        if let timer = self.locationCollectionTimer {
            timer.tolerance = 0.1 * delay
            DispatchQueue.main.async {
                // note: timer must be invalidated on the
                // same thread it was added to the run loop
                self.runLoop.add(timer: timer)
            }
        }
    }

    func invalidateLocationCollectionPoller(completion: (() -> Void)? = nil) {
        guard let timer = self.locationCollectionTimer else { return }
        DispatchQueue.main.async {
            self.runLoop.invalidate(timer: timer)
            completion?()
        }
    }
}

extension GeoPoller {

    var isRunning: Bool {
        guard let timer = locationCollectionTimer else {
            return false
        }
        return timer.isValid
    }
}
