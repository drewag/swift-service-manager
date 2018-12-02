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

            try parser.parse()

            var service = try PackageService()
            try service.resetDatabase(for: environment.parsedValue == "prod" ? .release : .debug, includingRole: false, includingMigration: true)
        }

        parser.command(named: "migrate", shortDescription: "Migrate to the latest version of the database spec") { parser in
            let environment = parser.string(named: "configuration")

            try parser.parse()

            var service = try PackageService()
            try service.migrateDatabase(for: environment.parsedValue == "prod" ? .release : .debug)
        }

        parser.command(named: "sql", shortDescription: "Execute an arbitrary sql command inside the database") { parser in
            let query = parser.string(named: "query")

            try parser.parse()

            var service = try PackageService()
            try service.queryDatabaseCommand(with: query.parsedValue).execute()
        }

        parser.command(named: "pull", shortDescription: "Pull the database from the deploy server") { parser in
            let from = parser.string(named: "from_configuration")
            let to = parser.optionalString(named: "to_configuration")

            try parser.parse()

            var packageService = try PackageService()
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
        let remoteDatabaseName = from.serviceEnvironment.databaseName(fromDomain: spec.domain)
        let remoteDatabaseUser = from.serviceEnvironment.databaseRole(fromDomain: spec.domain)
        let downloadPath = "\(from.remoteTempDirectoryPrefix)\(spec.domain).bk"
        try service.execute("PGPASSWORD=`cat \(from.remoteDirectoryPrefix)\(spec.domain)/database_password.string` pg_dump -h 127.0.0.1 \(remoteDatabaseName) -U \(remoteDatabaseUser) > \(downloadPath)")
        try ShellCommand("scp \(spec.domain):\(downloadPath) \(downloadPath)").execute()
        "done".log(as: .good)

        let localDatabaseName = to.serviceEnvironment.databaseName(fromDomain: spec.domain)
        "Applying to local database........".log()
        try ShellCommand("/usr/local/bin/psql -c 'DROP DATABASE IF EXISTS \(localDatabaseName)'").execute()
        try ShellCommand("/usr/local/bin/psql -c 'CREATE DATABASE \(localDatabaseName)'").execute()
        try ShellCommand("cat '\(downloadPath)'").pipe(to: "/usr/local/bin/psql \(to.serviceEnvironment.databaseName(fromDomain: spec.domain)) -q").execute()
        "done".log(as: .good)

        "Syncing data directories...".log()
        for directory in spec.dataDirectories {
            try ShellCommand("rsync -cazP \(spec.domain):\(from.remoteDirectoryPrefix)\(spec.domain)/\(directory) .", captureOutput: false).execute()
        }
        "done".log(as: .good)
    }
}
