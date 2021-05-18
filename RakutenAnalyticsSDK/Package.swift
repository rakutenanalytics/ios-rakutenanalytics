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
            url: "https://github.com/rakutentech/rakutentech/ios-analytics-framework/releases/download/8.0.1/RAnalyticsRelease-v8.0.1.zip",
            checksum: "3423c32615071da740e2eec680a76bf1fe7efbfb671f38ea472b31a6c24948ec"
        )
    ]
)
