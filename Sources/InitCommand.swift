//
//  InitCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

import Foundation
import CommandLineParser
import SwiftPlusPlus

struct InitCommand {
    static func handler(parser: Parser) throws {
        try parser.parse()

        try ShellCommand("swift package init --type executable").execute()

        var service = try PackageService()
        try service.initialize()
    }
}

extension PackageService {
    mutating func resetDatabase() throws {
        print("Setting up database...")
        try String(randomOfLength: 20).write(toFile: "database_password.string", atomically: true, encoding: .utf8)
        try self.command(subCommand: "db recreate-role").pipe(to: "psql").execute()
        try self.command(subCommand: "db recreate").pipe(to: "psql").execute()
    }
}

private extension PackageService {
    mutating func initialize() throws {
        print("Initializing package...")
        try self.generatePackageFile()
        try self.generateMain()
        try self.generateGitIgnore()
        try self.resetDatabase()
    }

    func generateGitIgnore() throws {
        print("Generating gitignore...")
        var ignore = ""
        ignore += ".DS_Store\n"
        ignore += "/.build\n"
        ignore += "/Packages\n"
        ignore += "/*.xcodeproj\n"
        ignore += "extra_info.json\n"
        ignore += "database_password.string\n"
        try ignore.write(toFile: ".gitignore", atomically: true, encoding: .utf8)
    }

    func generatePackageFile() throws {
        print("Generating package file...")
        var package = ""
        package += "import PackageDescription\n"
        package += "\n"
        package += "let package = Package(\n"
        package += "    name: \"\(name)\",\n"
        package += "    dependencies: [\n"
        package += "        .Package(url: \"https://github.com/drewag/swift-serve-kitura.git\", majorVersion: 5),\n"
        package += "    ]\n"
        package += ")\n"
        try package.write(toFile: "Package.swift", atomically: true, encoding: .utf8)
    }

    func generateMain() throws {
        print("Generating main...")
        var main = ""
        main += "import Foundation\n"
        main += "import SwiftServe\n"
        main += "import CommandLineParser\n"
        main += "import SwiftServeKitura\n"
        main += "import SwiftPlusPlus\n"
        main += "\n"
        main += "struct ExtraInfo: CodableType {\n"
        main += "\n"
        main += "    struct Keys {\n"
        main += "    }\n"
        main += "\n"
        main += "    init(decoder: DecoderType) throws {\n"
        main += "    }\n"
        main += "\n"
        main += "    func encode(_ encoder: EncoderType) {\n"
        main += "    }\n"
        main += "}\n"
        main += "\n"
        main += "let ServiceInstance = SwiftServeInstance<KituraServer, ExtraInfo>(\n"
        main += "    domain: \"\(name)\",\n"
        main += "    databaseChanges: [\n"
        main += "    ],\n"
        main += "    routes: [\n"
        main += "    ],\n"
        main += "    customizeCommandLineParser: { parser in\n"
        main += "    }\n"
        main += ")\n"
        try main.write(toFile: "Sources/main.swift", atomically: true, encoding: .utf8)
    }
}
