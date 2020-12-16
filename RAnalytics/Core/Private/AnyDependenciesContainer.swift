import Foundation

/// A container that can register any dependencies and resolve any types of dependencies
@objc public final class AnyDependenciesContainer: NSObject {
    private var swiftyContainer = SwiftyDependenciesContainer<NSObject>()

    /// Register an  instance (inheriting from NSObject)
    /// @warning Returns false if the instance is already registered
    /// @warning Register only one element per type.
    @objc @discardableResult public func registerObject(_ element: NSObject) -> Bool {
        swiftyContainer.register(element)
    }

    /// Returns an instance for a given type
    /// @warning Returns the first found instance for a given type (inheriting from NSObject)
    @objc public func resolveObject(_ typeToResolve: NSObject.Type) -> NSObject? {
        swiftyContainer.resolve(typeToResolve)
    }
}

// MARK: - Generic resolve - Only for Swift

extension AnyDependenciesContainer {
    /// Returns an instance for a given type
    /// @warning Returns the first found instance for a given type
    func resolve<T>(_ typeToResolve: T.Type) -> T? {
        swiftyContainer.resolve(typeToResolve)
    }
}

// MARK: - Swifty Dependencies Container

public struct SwiftyDependenciesContainer<T: Equatable> {
    private var elements = [T]()

    public init() {}

    /// Register an  instance conforming to Equatable protocol if it's not already contained
    /// Register only one element per type.
    @discardableResult public mutating func register(_ element: T) -> Bool {
        let contained = elements.contains { $0 == element }
        guard !contained else { return false }
        let containedType = elements.contains { type(of: $0) == type(of: element) }
        guard !containedType else { return false }
        elements.append(element)
        return true
    }

    /// Returns an instance for a given type
    /// @warning Returns the first found instance for a given type
    public func resolve<T>(_ typeToResolve: T.Type) -> T? {
        let result = elements.first {
            guard let element = $0 as? T else {
                return false
            }
            return type(of: element) == typeToResolve
        }

        return result as? T
    }
}
