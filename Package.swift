// swift-tools-version:5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RakutenAnalytics",
    platforms: [.iOS(.v15)],
    products: [.library(name: "RakutenAnalytics", targets: ["RakutenAnalytics"])],
    dependencies: [
             .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "7.6.2")),
             .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "13.6.2")),
             .package(url: "https://github.com/nalexn/ViewInspector", .upToNextMajor(from: "0.10.1")),
        ],
    targets: [
        .target(name: "RakutenAnalytics",
                dependencies: ["RAnalyticsSwiftLoader"],
                path: "Sources/Main",
                exclude: ["Core/SDK_TRACKING_GUIDE.md"],
                resources: [.process("Core/Assets"), 
                .copy("Resources/PrivacyInfo.xcprivacy")],
                publicHeadersPath: ""),

        .target(name: "RAnalyticsSwiftLoader",
                path: "Sources/RAnalyticsSwiftLoader",
                // publicHeadersPath is mandatory for Swift >= 5.5
                // Note: This path is relative to the target.
                publicHeadersPath: ""),

        .target(name: "RAnalyticsTestHelpers",
                dependencies: ["RakutenAnalytics",
                               "Quick",
                               "Nimble",
                               "ViewInspector"],
                path: "UnitTestApp/Tests/RAnalyticsTestHelpers",
                resources: [.process("Resources")]),

        .testTarget(name: "Functional", 
                    dependencies: ["RakutenAnalytics", "RAnalyticsTestHelpers"],
                    path: "UnitTestApp/Tests/Functional"),

        .testTarget(name: "UtilsSpec", dependencies: ["RakutenAnalytics", "RAnalyticsTestHelpers"],
                    path: "UnitTestApp/Tests/UtilsSpec"),

        .testTarget(name: "Integration",
                    dependencies: ["RakutenAnalytics", "RAnalyticsTestHelpers"],
                    path: "UnitTestApp/Tests/Integration",
                    exclude: ["IntegrationTests-Info.plist"]),

        .testTarget(name: "Unit",
                    dependencies: ["RakutenAnalytics", "RAnalyticsTestHelpers"],
                    path: "UnitTestApp/Tests/Unit",
                    exclude: ["Info.plist"],
                    resources: [.process("Resources")]),

        .testTarget(name: "GeoSpec",
                    dependencies: ["RakutenAnalytics", "RAnalyticsTestHelpers"], 
                    path: "UnitTestApp/Tests/GeoSpec")
    ],
    swiftLanguageVersions: [.v5]
)
