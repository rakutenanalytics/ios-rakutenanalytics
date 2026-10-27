import Network
import SystemConfiguration
import Foundation

/// Reachability status
enum RATReachabilityStatus: Int {
    case offline
    case wwan
    case wifi
}

protocol ReachabilityType {
    var connection: Reachability.Connection { get }
    var flags: SCNetworkReachabilityFlags? { get }
    var connectionUpdates: AsyncStream<Reachability.Connection> { get }
}

class Reachability: ReachabilityType {

    enum Connection {
        case unavailable
        case wifi
        case cellular

        var isAvailable: Bool {
            return [.wifi, .cellular].contains(self)
        }
    }

    private let connectionUpdatesContinuation: AsyncStream<Connection>.Continuation
    let connectionUpdates: AsyncStream<Connection>
    private let monitor: NWPathMonitor
    private static let monitorQueueKey = DispatchSpecificKey<Void>()
    private let monitorQueue: DispatchQueue

    private let flagsQueue = DispatchQueue(label: "ReachabilityFlagsQueue", qos: .default)
    private var _flags: SCNetworkReachabilityFlags?
    private(set) var flags: SCNetworkReachabilityFlags? {
        get {
            return flagsQueue.sync { _flags }
        }
        set {
            flagsQueue.sync { _flags = newValue }
            emitConnectionUpdate()
        }
    }

    var connection: Connection {
        guard let flags = flags else {
            return .unavailable
        }

        #if targetEnvironment(simulator)
        return flags.isReachableFlagSet ? .wifi : .unavailable
        #else
        return flags.connection
        #endif
    }

    init() {
        let (stream, continuation) = AsyncStream<Connection>.makeStream()
        self.connectionUpdates = stream
        self.connectionUpdatesContinuation = continuation
        self.monitor = NWPathMonitor()
        let monitorQueue = DispatchQueue(label: "ReachabilityQueue", qos: .default)
        monitorQueue.setSpecific(key: Self.monitorQueueKey, value: ())
        self.monitorQueue = monitorQueue
        continuation.yield(.unavailable)
        startNotifier()
    }

    deinit {
        connectionUpdatesContinuation.finish()
        stopNotifier()
    }

    private func startNotifier() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateFlags(from: path)
        }
        monitor.start(queue: monitorQueue)
    }

    private func stopNotifier() {
        let stop = { [monitor] in
            monitor.pathUpdateHandler = nil
            monitor.cancel()
        }
        if DispatchQueue.getSpecific(key: Self.monitorQueueKey) != nil {
            stop()
        } else {
            monitorQueue.sync(execute: stop)
        }
    }

    private func updateFlags(from path: NWPath) {
        var newFlags = SCNetworkReachabilityFlags()

        if path.status == .satisfied {
            newFlags.insert(.reachable)
        }

        if path.isExpensive {
            newFlags.insert(.isWWAN)
        }

        self.flags = newFlags
    }

    private func emitConnectionUpdate() {
        connectionUpdatesContinuation.yield(connection)
    }

    #if DEBUG
    /// Test-only setter for `flags`
    func setFlagsForTesting(_ newFlags: SCNetworkReachabilityFlags) {
        stopNotifier()
        self.flags = newFlags
    }
    #endif
}

extension SCNetworkReachabilityFlags {

    var reachabilityStatus: RATReachabilityStatus {
        if !contains(.reachable) || contains(.connectionRequired) {
            return .offline

        } else if contains(.isWWAN) {
            return .wwan

        } else {
            return .wifi
        }
    }

    var connection: Reachability.Connection {
        guard isReachableFlagSet else { return .unavailable }

        #if targetEnvironment(simulator)
        // In the simulator, always return `.wifi` if reachable
        return .wifi
        #else
        if isOnWWANFlagSet {
            return .cellular
        }
        return .wifi
        #endif
    }

    var isOnWWANFlagSet: Bool {
        #if os(iOS)
        return contains(.isWWAN)
        #else
        return false
        #endif
    }

    var isReachableFlagSet: Bool {
        return contains(.reachable)
    }

    var description: String {
        let wwan = isOnWWANFlagSet ? "W" : "-"
        let reachable = isReachableFlagSet ? "R" : "-"

        return "\(wwan)\(reachable)"
    }
}
