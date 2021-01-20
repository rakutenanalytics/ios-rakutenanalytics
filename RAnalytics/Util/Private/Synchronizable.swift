internal enum Synchronizable {

    /// This is a Swift interpretation of Obj-C `@synchronized`
    static func withSynchronized(_ objects: [Lockable], do: () -> Void) { // swiftlint:disable:this identifier_name
        objects.forEach { $0.lock() }
        `do`()
        objects.forEach { $0.unlock() }
    }
}

internal protocol Lockable {

    /// Lock resource for caller's thread use
    func lock()

    /// Unlock resource. Access from other threads will be resumed
    func unlock()
}

/// Object wrapper that conforms to Lockable protocol.
/// Use it to control access to the resource in multi threaded environment.
/// When lock() has been called on some thread, only that thread will be able to access the resource.
/// Other threads will synchronously wait for unlock() call to continue.
internal class LockableObject<T>: Lockable {

    private var resource: T
    private var lockingThread: Thread?
    private let dispatchGroup = DispatchGroup()
    var isLocked: Bool {
        return lockingThread != nil
    }

    init(_ resource: T) {
        self.resource = resource
    }

    deinit {
        unlock()
    }

    func lock() {
        lockingThread = Thread.current
        dispatchGroup.enter()
    }

    func unlock() {
        if isLocked {
            dispatchGroup.leave()
        }
        lockingThread = nil
    }

    func get() -> T {
        if isLocked, lockingThread != Thread.current {
            dispatchGroup.wait()
            return resource
        } else {
            return resource
        }
    }

    func set(value: T) {
        if isLocked, lockingThread != Thread.current {
            dispatchGroup.wait()
            resource = value
        } else {
            resource = value
        }
    }
}
