// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "ssm",
    dependencies: [
        .package(url: "https://github.com/drewag/command-line-parser.git", from: "2.0.0"),
        .package(url: "https://github.com/drewag/Swiftlier.git", from: "4.0.0"),
        .package(url: "https://github.com/drewag/swift-serve.git", from: "14.4.0"),
        .package(url: "https://github.com/jakeheis/Shout.git", from: "0.4.0"),
    ],
    targets: [
        .target(name: "ssm", dependencies: ["CommandLineParser", "Swiftlier", "SwiftServe", "Shout"], path: "Sources"),
    ]
)
