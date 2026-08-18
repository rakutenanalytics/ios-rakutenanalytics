// swift-tools-version:5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RakutenAnalytics",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [.library(name: "RakutenAnalytics", targets: ["RakutenAnalytics"])],
    targets: [
        .target(name: "RakutenAnalytics",
                dependencies: ["RAnalyticsSwiftLoader"],
                path: "Sources/Main",
                resources: [.process("Core/Assets"),
                .copy("Resources/PrivacyInfo.xcprivacy")],
                publicHeadersPath: ""),

        .target(name: "RAnalyticsSwiftLoader",
                path: "Sources/RAnalyticsSwiftLoader",
                // publicHeadersPath is mandatory for Swift >= 5.5
                // Note: This path is relative to the target.
                publicHeadersPath: "")
    ],
    swiftLanguageVersions: [.v5]
)

// Tests are not exposed as SPM test targets. Run them from UnitTestApp/UnitTestApp.xcodeproj
// with the Host app, which provides the required UIKit lifecycle and serial execution.
