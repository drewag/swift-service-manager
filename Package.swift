import PackageDescription

let package = Package(
    name: "ssm",
    dependencies: [
        .Package(url: "https://github.com/drewag/command-line-parser.git", majorVersion: 2),
        .Package(url: "https://github.com/drewag/Swiftlier.git", majorVersion: 4),
        .Package(url: "https://github.com/drewag/swift-serve.git", majorVersion: 11),
    ]
)
