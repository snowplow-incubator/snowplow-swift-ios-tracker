// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "SnowplowTracker",
    products: [
        .library(
            name: "SnowplowTracker",
            targets: ["SnowplowTracker"]),
    ],
    dependencies: [
        .package(name: "FMDB", url: "https://github.com/ccgus/fmdb", from: "2.7.6")
    ],
    targets: [
        .target(
            name: "SnowplowTracker",
            dependencies: ["FMDB"],
            path: "./Sources"),
        .testTarget(
            name: "Tests",
            dependencies: ["SnowplowTracker"],
            path: "Tests")
    ]
)
