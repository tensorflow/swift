// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Metaprogramming",
    products: [
        .library(
            name: "SIL",
            type: .dynamic,
            targets: ["SIL"]),
        .library(
            name: "Quote",
            type: .dynamic,
            targets: ["Quote"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SIL",
            dependencies: []),
        .testTarget(
            name: "SILTests",
            dependencies: ["SIL"],
            path: "Tests/SILTests"),
        .target(
            name: "Quote",
            dependencies: []),
        .testTarget(
            name: "QuoteTests",
            dependencies: ["Quote"],
            path: "Tests/QuoteTests"),
    ]
)
