//
//  DatabaseCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/21/17.
//
//

import CommandLineParser
import SwiftPlusPlus

struct DatabaseCommand {
    static func handler(parser: Parser) throws {
        parser.command(named: "reset") { parser in
            try parser.parse()

            var service = try PackageService()
            try service.resetDatabase()
        }

        parser.command(named: "migrate") { parser in
            try parser.parse()

            var service = try PackageService()
            try service.migrateDatabase()
        }

        try parser.parse()
    }
}

extension PackageService {
    mutating func resetDatabase() throws {
        try String(randomOfLength: 20).write(toFile: "database_password.string", atomically: true, encoding: .utf8)
        try self.command(named: "Resetting database...", subCommand: "db recreate-role").pipe(to: "psql -q").execute()
        try self.command(subCommand: "db recreate").pipe(to: "psql -q").execute()
        try self.migrateDatabase()
    }

    mutating func migrateDatabase() throws {
        try self.command(named: "Migrating database...", subCommand: "db migrate").execute()
    }
}
