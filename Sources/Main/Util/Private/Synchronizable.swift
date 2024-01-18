import Foundation

internal enum Synchronizable {

    /// This is a Swift interpretation of Obj-C `@synchronized`
    static func withSynchronized(_ objects: [LockableResource], do block: () -> Void) { // swiftlint:disable:this identifier_name
        objects.forEach { $0.lock() }
        block()
        objects.forEach { $0.unlock() }
    }
}
