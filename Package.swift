// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MySQLDriver",
    products: [
        .library(
            name: "MySQLDriver",
            targets: ["MySQLDriver"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MySQLDriver",
            dependencies: [])
    ]
)
