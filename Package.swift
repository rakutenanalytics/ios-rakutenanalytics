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
                      .upToNextMajor(from: "2.1.0")
             ),

             .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "4.0.0")),

             .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.1.0"))
        ],
    targets: [
        .target(name: "RAnalytics",
                dependencies: ["RAnalyticsSwiftLoader",
                               .productItem(name: "RLogger", package: "RSDKUtils", condition: .none),
                               .productItem(name: "RSDKUtilsMain", package: "RSDKUtils", condition: .none)],
                path: "Sources/Main",
                exclude: ["Core/SDK_TRACKING_GUIDE.md"],
                resources: [.process("Core/Assets")]),

        .target(name: "RAnalyticsSwiftLoader",
                path: "Sources/RAnalyticsSwiftLoader"),

        .target(name: "RAnalyticsTestHelpers",
                dependencies: ["RAnalytics",
                               "Quick",
                               "Nimble",
                               .productItem(name: "RSDKUtilsNimble", package: "RSDKUtils", condition: .none),
                               .productItem(name: "RSDKUtilsTestHelpers", package: "RSDKUtils", condition: .none)],
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
