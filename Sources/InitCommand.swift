//
//  InitCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

import Foundation
import CommandLineParser
import Swiftlier

struct InitCommand: CommandHandler {
    static let name: String = "init"
    static let shortDescription: String? = "Initialize a new web service project and setup database"
    static let longDescription: String? = nil

    static func handler(parser: Parser) throws {
        try parser.parse()

        "Initializing package...".log()
        try ShellCommand("swift package init --type executable").execute()

        var service = try PackageService()
        try service.initialize()
    }
}

private extension PackageService {
    mutating func initialize() throws {
        try self.generateSwiftVersion()
        try self.generatePackageFile()
        try self.generateMain()
        try self.generateGitIgnore()
        try self.resetDatabase()
    }

    func generateSwiftVersion() throws {
        let _ = try FileSystem.default.workingDirectory
            .file(".swift-version")
            .createFile(containing: "4.0".data(using: .utf8), canOverwrite: true)
    }

    func generateGitIgnore() throws {
        let ignore = """
            .DS_Store
            .build/
            Packages/
            *.xcodeproj/
            extra_info.json
            database_password.string
            *.swp
            *.swo
            """
        let _ = try FileSystem.default.workingDirectory
            .file(".gitignore")
            .createFile(containing: ignore.data(using: .utf8), canOverwrite: true)
    }

    func generatePackageFile() throws {
        let package = """
            import PackageDescription

            let package = Package(
                name: "\(name)",
                dependencies: [
                    .Package(url: "https://github.com/drewag/swift-serve-kitura.git", majorVersion: 9),
                ]
            )
            """

        let _ = try FileSystem.default.workingDirectory
            .file("Package.swift")
            .createFile(containing: package.data(using: .utf8), canOverwrite: true)
    }

    func generateMain() throws {
        let main = """
            import Foundation
            import SwiftServe
            import CommandLineParser
            import SwiftServeKitura
            import Swiftlier

            struct ExtraInfo: Codable {
            }

            let ServiceInstance = SwiftServeInstance<KituraServer, ExtraInfo>(
                domain: "\(name)",
                databaseChanges: [
                ],
                routes: [
                ],
                customizeCommandLineParser: { parser in
                }
            )
            ServiceInstance.run()
            """
        let _ = try FileSystem.default.workingDirectory
            .subdirectory("Sources")
            .file("main.swift")
            .createFile(containing: main.data(using: .utf8), canOverwrite: true)
    }
}
