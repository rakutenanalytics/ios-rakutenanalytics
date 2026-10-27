import Foundation

/// This wrapper ensures synchronized access to the value only for getter and setter.
/// Mutating functions, subscript, incrementation etc. are not synchronized by default -
/// use `mutate` function to ensure operation atomicity.
///
/// Marked `@unchecked Sendable` because access is serialized on an internal queue.
/// Callers must not share non-Sendable `Value` types across task boundaries.
@propertyWrapper
final class AtomicGetSet<Value>: @unchecked Sendable {
    private let queue = PropertyQueueGenerator.spawnQueue(domain: "RAnalytics.AtomicProperty")
    private var value: Value

    init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    var wrappedValue: Value {
        get {
            return queue.sync { value }
        }
        set {
            queue.sync(flags: .barrier) { value = newValue }
        }
    }

    func mutate(_ mutation: (inout Value) -> Void) {
        queue.sync(flags: .barrier) {
            mutation(&value)
        }
    }
}

private struct PropertyQueueGenerator {
    private static var lastQueueNumber = UInt(0)

    static func spawnQueue(domain: String) -> DispatchQueue {
        lastQueueNumber += 1
        return DispatchQueue(label: domain + "\(lastQueueNumber))", attributes: .concurrent)
    }
}
