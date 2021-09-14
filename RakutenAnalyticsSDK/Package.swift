// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RAnalytics",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "RAnalytics",
            targets: ["RAnalytics"]),
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "RAnalytics",
            url: "https://github.com/rakutentech/ios-analytics-framework/releases/download/8.2.1/RAnalyticsRelease-v8.2.1.zip",
            checksum: "6fa87cefc744fd2e313f05c851ff1561bc337e9508b8e46b7ed93853f536c560"
        )
    ]
)
