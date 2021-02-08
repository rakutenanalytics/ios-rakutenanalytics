/// This wrapper ensures synchronized access to the value only for getter and setter.
/// Mutating functions, subscript, incrementation etc. are not synchronized.
@propertyWrapper
public struct AtomicGetSet<Value> {
    // swiftlint:disable:next todo
    /// FIXME: Make all internal again after tests are refactored
    private let queue = PropertyQueueGenerator.spawnQueue(domain: "RAnalytics.Core.AtomicProperty")
    private var value: Value

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            return queue.sync { value }
        }
        set {
            queue.sync { value = newValue }
        }
    }
}

private struct PropertyQueueGenerator {
    private static var lastQueueNumber = UInt(0)

    static func spawnQueue(domain: String) -> DispatchQueue {
        lastQueueNumber += 1
        return DispatchQueue(label: domain + "\(lastQueueNumber))")
    }
}
