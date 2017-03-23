//
//  CustomCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/23/17.
//
//

import Foundation
import CommandLineParser
import SwiftPlusPlus

struct CustomCommand: CommandHandler {
    static let name: String = "custom"
    static let shortDescription: String? = "Execute commands specific to the current service"
    static let longDescription: String? = nil

    static func handler(parser: Parser) throws {
        do {
            var service = try PackageService()
            for scheme in try service.loadSpec(for: .debug).extraSchemes {
                parser.command(named: scheme.name.replacingOccurrences(of: " ", with: "-"), handler: { parser in
                    try parser.parse()

                    var service = try PackageService()
                    try service.command(
                        named: "Calling command...",
                        captureOutput: false,
                        for: .debug,
                        subCommand: scheme.arguments.joined(separator: " ")
                    ).execute()
                })
            }
        }
        catch {}

        try parser.parse()
    }
}

private extension PackageService {
    mutating func update(for environment: Environment) throws {
        "Pulling down changes to repository...".log()
        try ShellCommand("git pull").execute()
        "Updating dependencies...".log()
        try ShellCommand("swift package update", captureOutput: false).execute()
        try self.migrateDatabase(for: environment)
    }
}
