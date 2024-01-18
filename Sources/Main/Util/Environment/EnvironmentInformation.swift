import Foundation

enum EnvironmentInformation {
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
}
