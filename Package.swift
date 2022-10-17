// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RAnalytics",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "RAnalytics", targets: ["RAnalytics"])
    ],
    dependencies: [
             .package(name: "RSDKUtils",
                      url: "https://github.com/rakutentech/ios-sdkutils.git",
                      .upToNextMinor(from: "3.0.0")
             ),

             .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "5.0.0")),

             .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.1.0")),

             .package(url: "https://github.com/nalexn/ViewInspector", .upToNextMajor(from: "0.9.1")),

             .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .upToNextMajor(from: "9.1.0"))
        ],
    targets: [
        .target(name: "RAnalytics",
                dependencies: ["RAnalyticsSwiftLoader",
                               .product(name: "RLogger", package: "RSDKUtils"),
                               .product(name: "RSDKUtilsMain", package: "RSDKUtils")],
                path: "Sources/Main",
                exclude: ["Core/SDK_TRACKING_GUIDE.md"],
                resources: [.process("Core/Assets")]),

        .target(name: "RAnalyticsSwiftLoader",
                path: "Sources/RAnalyticsSwiftLoader"),

        .target(name: "RAnalyticsTestHelpers",
                dependencies: ["RAnalytics",
                               "Quick",
                               "Nimble",
                               "ViewInspector",
                               "OHHTTPStubs",
                               .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
                               .product(name: "RSDKUtilsNimble", package: "RSDKUtils"),
                               .product(name: "RSDKUtilsTestHelpers", package: "RSDKUtils")],
                path: "Tests/RAnalyticsTestHelpers",
                resources: [.process("Resources")]),

        .testTarget(name: "Functional", dependencies: ["RAnalytics", "RAnalyticsTestHelpers"]),

        .testTarget(name: "Integration",
                    dependencies: ["RAnalytics", "RAnalyticsTestHelpers"],
                    exclude: ["IntegrationTests-Info.plist"]),

        .testTarget(name: "Unit",
                    dependencies: ["RAnalytics", "RAnalyticsTestHelpers"],
                    exclude: ["Info.plist"],
                    resources: [.process("Resources")])
    ],
    swiftLanguageVersions: [.v5]
)
