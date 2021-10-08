import protocol RSDKUtils.LockableResource
internal enum Synchronizable {

    /// This is a Swift interpretation of Obj-C `@synchronized`
    static func withSynchronized(_ objects: [LockableResource], do: () -> Void) { // swiftlint:disable:this identifier_name
        objects.forEach { $0.lock() }
        `do`()
        objects.forEach { $0.unlock() }
    }
}
