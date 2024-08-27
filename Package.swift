// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Voskcap",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "Voskcap",
            targets: ["VoskCapPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", branch: "main")
    ],
    targets: [
        .target(
            name: "VoskCapPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/VoskCapPlugin"),
        .testTarget(
            name: "VoskCapPluginTests",
            dependencies: ["VoskCapPlugin"],
            path: "ios/Tests/VoskCapPluginTests")
    ]
)