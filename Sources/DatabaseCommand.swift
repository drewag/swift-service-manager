//
//  DatabaseCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/21/17.
//
//

import CommandLineParser
import Swiftlier
import SwiftServe

struct DatabaseCommand: CommandHandler {
    static let name: String = "db"
    static let shortDescription: String? = "Has multiple subcommands for managing your local database"
    static let longDescription: String? = nil

    static func handler(parser: Parser) throws {
        parser.command(named: "reset", shortDescription: "Delete the database (if it exists) and recreate it") { parser in
            try parser.parse()

            var service = try PackageService()
            try service.resetDatabase()
        }

        parser.command(named: "migrate", shortDescription: "Migrate to the latest version of the database spec") { parser in
            try parser.parse()

            var service = try PackageService()
            try service.migrateDatabase(for: .debug)
        }

        parser.command(named: "sql", shortDescription: "Execute an arbitrary sql command inside the database") { parser in
            let query = parser.string(named: "query")

            try parser.parse()

            var service = try PackageService()
            try service.queryDatabaseCommand(with: query.parsedValue).execute()
        }

        try parser.parse()
    }
}

extension PackageService {
    mutating func resetDatabase() throws {
        try String(randomOfLength: 20).write(toFile: "dev_database_password.string", atomically: true, encoding: .utf8)
        try String(randomOfLength: 20).write(toFile: "database_password.string", atomically: true, encoding: .utf8)
        try self.command(named: "Resetting database...", subCommand: "db recreate-role").pipe(to: "psql -q").execute()
        try self.command(subCommand: "db recreate").pipe(to: "psql -q").execute()
        try self.migrateDatabase(for: .debug)
    }

    mutating func migrateDatabase(for environment: Environment) throws {
        try self.command(named: "Migrating database...", for: environment, subCommand: "db migrate").execute()
    }
}
