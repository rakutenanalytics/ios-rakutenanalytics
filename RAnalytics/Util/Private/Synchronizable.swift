internal enum Synchronizable {

    /// This is a Swift interpretation of Obj-C `@synchronized`
    static func withSynchronized(_ objects: [LockableResource], do: () -> Void) { // swiftlint:disable:this identifier_name
        objects.forEach { $0.lock() }
        `do`()
        objects.forEach { $0.unlock() }
    }
}

/// Protocol to mark object that have resources that can be thread locked
internal protocol Lockable {
    var resourcesToLock: [LockableResource] { get }
}

internal protocol LockableResource {

    /// Lock resource for caller's thread use
    func lock()

    /// Unlock resource. Access from other threads will be resumed
    func unlock()
}

/// Object-wrapper that conforms to LockableResource protocol.
/// Used to control getter and setter of given resource. Can be used to create atomic transaction.
///
/// When lock() has been called on some thread, only that thread will be able to access the resource.
/// Other threads will synchronously wait for unlock() call to continue.
/// - Note: get() and set() are not thread-safe by itself
internal class LockableObject<T>: LockableResource {
    private var resource: T
    private let dispatchGroup = DispatchGroup()
    private let transactionQueue = DispatchQueue(label: "LockableObject.Transaction", qos: .default)
    private var lockingThread: Thread?
    private(set) var lockCount: UInt = 0

    var isLocked: Bool { transactionQueue.sync { _isLocked } }
    private var _isLocked: Bool { lockCount > 0 }

    init(_ resource: T) {
        self.resource = resource
    }

    deinit {
        for _ in 0..<lockCount {
            dispatchGroup.leave()
        }
    }

    func lock() {
        let currentThread = Thread.current
        var waitAndRetry = false
        transactionQueue.sync {
            guard !self.checkIfThreadShouldWait(threadSafe: false) else {
                waitAndRetry = true
                return
            }
            dispatchGroup.enter()
            lockCount += 1
            assert(lockingThread == nil || lockingThread == currentThread)
            lockingThread = currentThread
        }
        if waitAndRetry {
            dispatchGroup.wait()
            lock()
        }
    }

    func unlock() {
        transactionQueue.sync {
            guard !self.checkIfThreadShouldWait(threadSafe: false) else {
                return
            }
            if lockCount > 0 {
                lockCount -= 1
                if lockCount == 0 {
                    lockingThread = nil
                }
                dispatchGroup.leave()
            }
        }
    }

    func get() -> T {
        if checkIfThreadShouldWait(threadSafe: true) {
            dispatchGroup.wait()
            return resource
        } else {
            return resource
        }
    }

    func set(value: T) {
        if checkIfThreadShouldWait(threadSafe: true) {
            dispatchGroup.wait()
            resource = value
        } else {
            resource = value
        }
    }

    private func checkIfThreadShouldWait(threadSafe: Bool) -> Bool {
        let currentThread = Thread.current
        let shouldWait: () -> Bool = { [self] in
            assert(!(_isLocked && lockingThread == nil), "Thread was deallocated before calling unlock()")
            return _isLocked && lockingThread != nil && lockingThread != currentThread
        }
        return threadSafe ? transactionQueue.sync(execute: shouldWait) : shouldWait()
    }
}
