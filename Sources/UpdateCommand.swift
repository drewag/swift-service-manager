//
//  UpdateCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/22/17.
//
//

import Foundation
import CommandLineParser
import SwiftPlusPlus

struct UpdateCommand: CommandHandler {
    static let name: String = "update"
    static let shortDescription: String? = "Update to the latest version"
    static let longDescription: String? = "Update the repository to the latest code and migrate the database if necessary"

    static func handler(parser: Parser) throws {
        let environment = parser.optionalString(named: "environment")

        try parser.parse()

        var service = try PackageService()
        try service.update(for: environment.parsedValue == "prod" ? .release : .debug)
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
