// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "SIL",
    products: [
        .library(
            name: "SIL",
            type: .dynamic,
            targets: ["SIL"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SIL",
            dependencies: []),
        .testTarget(
            name: "SILTests",
            dependencies: ["SIL"],
            path: "Tests/SILTests")
    ]
)
