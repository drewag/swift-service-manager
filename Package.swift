// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "ssm",
    platforms: [.macOS(.v10_11)],
    dependencies: [
        .package(url: "https://github.com/drewag/swift-serve.git", from: "18.0.0"),
        .package(url: "https://github.com/jakeheis/Shout.git", from: "0.4.0"),
    ],
    targets: [
        .target(name: "ssm", dependencies: ["SwiftServe", "Shout"], path: "Sources"),
    ]
)
