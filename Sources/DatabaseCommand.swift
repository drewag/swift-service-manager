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
            let environment = parser.string(named: "configuration")
            let executable = parser.optionalString(named: "executable")

            try parser.parse()

            var service = PackageService(executableName: executable.parsedValue)
            try service.resetDatabase(for: environment.parsedValue == "prod" ? .release : .debug, includingRole: true, includingMigration: true)
        }

        parser.command(named: "migrate", shortDescription: "Migrate to the latest version of the database spec") { parser in
            let environment = parser.string(named: "configuration")
            let executable = parser.optionalString(named: "executable")

            try parser.parse()

            var service = PackageService(executableName: executable.parsedValue)
            try service.migrateDatabase(for: environment.parsedValue == "prod" ? .release : .debug)
        }

        parser.command(named: "pull", shortDescription: "Pull the database from the deploy server") { parser in
            let from = parser.string(named: "from_configuration")
            let to = parser.optionalString(named: "to_configuration")
            let executable = parser.optionalString(named: "executable")

            try parser.parse()

            var packageService = PackageService(executableName: executable.parsedValue)
            try packageService.pullDatabase(
                for: from.parsedValue == "prod" ? .release : .debug,
                into: to.parsedValue == "prod" ? .release : .debug
            )
        }

        try parser.parse()
    }
}

extension PackageService {
    mutating func resetDatabase(for environment: Environment, includingRole: Bool, includingMigration: Bool) throws {
        if includingRole {
            try String(randomOfLength: 20).write(toFile: "database_password.string", atomically: true, encoding: .utf8)
            try self.command(named: "Resetting database...", subCommand: "db recreate-role").pipe(to: "/usr/local/bin/psql -q").execute()
        }
        try self.command(subCommand: "db recreate").pipe(to: "/usr/local/bin/psql -q").execute()
        if includingMigration {
            try self.migrateDatabase(for: .debug)
        }
    }

    mutating func migrateDatabase(for environment: Environment) throws {
        try self.command(named: "Migrating database...", for: environment, subCommand: "db migrate").execute()
    }

    mutating func pullDatabase(for from: Environment, into to: Environment) throws {
        let spec = try self.loadSpec(for: .debug)

        "Downloading \(from.name) database...".log(terminator: "")
        let service = try RemoteServerService(host: spec.domain)
        let remoteDatabaseName = from.serviceEnvironment.databaseName(from: spec)
        let remoteDatabaseUser = from.serviceEnvironment.databaseRole(from: spec)
        let downloadPath = "\(from.remoteTempDirectoryPrefix)\(spec.domain).bk"
        try service.execute("PGPASSWORD=`cat \(from.remoteDirectoryPrefix)\(spec.domain)/Config/database_password.string` pg_dump -h 127.0.0.1 \(remoteDatabaseName) -U \(remoteDatabaseUser) > \(downloadPath)")
        try ShellCommand("scp \(spec.domain):\(downloadPath) \(downloadPath)").execute()
        "done".log(as: .good)

        let localDatabaseName = to.serviceEnvironment.databaseName(from: spec)
        "Applying to local database........".log()
        try ShellCommand("/usr/local/bin/psql -c 'DROP DATABASE IF EXISTS \(localDatabaseName)'").execute()
        try ShellCommand("/usr/local/bin/psql -c 'CREATE DATABASE \(localDatabaseName)'").execute()
        try ShellCommand("cat '\(downloadPath)'").pipe(to: "/usr/local/bin/psql \(to.serviceEnvironment.databaseName(from: spec)) -q").execute()
        "done".log(as: .good)

        "Syncing data directories...".log()
        for directory in spec.dataDirectories {
            try ShellCommand("rsync -cazP \(spec.domain):\(from.remoteDirectoryPrefix)\(spec.domain)/\(directory) .", captureOutput: false).execute()
        }
        "done".log(as: .good)
    }
}
