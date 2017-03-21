import PackageDescription

let package = Package(
    name: "ssm",
    dependencies: [
        .Package(url: "https://github.com/drewag/command-line-parser.git", majorVersion: 1),
        .Package(url: "https://github.com/drewag/SwiftPlusPlus.git", majorVersion: 1),
    ]
)
