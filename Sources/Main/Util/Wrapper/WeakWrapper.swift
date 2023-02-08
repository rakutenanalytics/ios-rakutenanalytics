/// Class that stores weak reference to the wrapped object.
/// It can be used used to avoid retain cycles in some cases.
class WeakWrapper<T> {
    // T cannot be restricted to AnyObject in order to support protocols
    private weak var internalValue: AnyObject?
    var value: T? {
        internalValue as? T
    }

    init(value: AnyObject) {
        internalValue = value
    }
}
