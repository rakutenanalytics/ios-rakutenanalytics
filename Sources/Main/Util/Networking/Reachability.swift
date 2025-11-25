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
    func addObserver(_ observer: ReachabilityObserver)
    func removeObserver(_ observer: ReachabilityObserver)
}

protocol ReachabilityObserver: AnyObject {
    func reachabilityChanged(_ reachability: ReachabilityType)
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

    private var observers = [WeakWrapper<ReachabilityObserver>]()
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "ReachabilityQueue", qos: .default)
    private let notificationQueue = DispatchQueue.main
    
    private let flagsQueue = DispatchQueue(label: "ReachabilityFlagsQueue", qos: .default)
    private var _flags: SCNetworkReachabilityFlags?
    private(set) var flags: SCNetworkReachabilityFlags? {
        get {
            return flagsQueue.sync { _flags }
        }
        set {
            flagsQueue.sync { _flags = newValue }
            notifyReachabilityChanged()
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
        self.monitor = NWPathMonitor()
        startNotifier()
    }

    deinit {
        stopNotifier()
    }

    func addObserver(_ observer: ReachabilityObserver) {
        observers.append(WeakWrapper(value: observer))
    }

    func removeObserver(_ observer: ReachabilityObserver) {
        observers.removeAll { $0.value === observer }
    }

    private func startNotifier() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.updateFlags(from: path)
        }
        monitor.start(queue: monitorQueue)
    }

    private func stopNotifier() {
        monitor.cancel()
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

    private func notifyReachabilityChanged() {
        notificationQueue.async { [weak self] in
            guard let self = self else { return }
            self.observers.forEach { $0.value?.reachabilityChanged(self) }
        }
    }
    
    #if DEBUG
    /// Test-only setter for `flags`
    func setFlagsForTesting(_ newFlags: SCNetworkReachabilityFlags) {
        self.flags = newFlags
        notifyReachabilityChanged()
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
