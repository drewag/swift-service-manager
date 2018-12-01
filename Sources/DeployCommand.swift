//
//  DeployCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 11/30/18.
//

import Foundation
import CommandLineParser
import Swiftlier

struct DeployCommand: CommandHandler, ErrorGenerating {
    static let name: String = "deploy"
    static let shortDescription: String? = "Deploy to a server"
    static let longDescription: String? = nil

    static func handler(parser: Parser) throws {
        let environmentPromise = parser.string(named: "configuration")

        try parser.parse()

        let environment: Environment = environmentPromise.parsedValue == "prod" ? .release : .debug

        do {
            try ShellCommand("git diff-index --quiet HEAD --").execute()
        }
        catch {
            throw self.userError("deploying", because: "you have uncommited changes")
        }

        try ShellCommand("git fetch").execute()
        let count = try ShellCommand("git rev-list --count origin/master..master").execute().chomp()
        guard count == "0" else {
            throw self.userError("deploying", because: "you have unpushed commits")
        }

        var packageService = try PackageService()
        let description = try packageService.loadDescription()
        guard description.executables.count <= 1 else {
            throw self.userError("deploying", because: "multiple executables were found and that is not supported yet")
        }
        guard let executable = description.executables.first else {
            throw self.userError("deploying", because: "no executable found")
        }

        let spec = try packageService.loadSpec(for: .release) // Always build from prod because that is what will be used on the server

        try packageService.test()

        "Deploying \(environment.name)...".log()
        "----------------------------------".log()

        let repository = try ShellCommand("git config --get remote.origin.url").execute().chomp()

        var service = try RemoteServerService(host: spec.domain)
        let tempDirectory = "\(environment.remoteTempDirectoryPrefix)\(spec.domain)"
        let finalDirectory = "\(environment.remoteDirectoryPrefix)\(spec.domain)"

        "Cloning latest code......".log(terminator: "")
        try service.execute("rm -r \(tempDirectory) || true")
        try service.execute("git clone \(repository) \(tempDirectory)")
        try service.execute("cp \(finalDirectory)/database_password.string \(tempDirectory)/database_password.string")
        try service.execute("cp \(finalDirectory)/extra_info.json \(tempDirectory)/extra_info.json")
        "done".log(as: .good)

        try service.change(to: tempDirectory)

        "Updating packages.............".log(terminator: "")
        try service.execute(swift: "package update")
        "done".log(as: .good)

        "Building for debug............".log(terminator: "")
        try service.execute(swift: "build")
        "done".log(as: .good)

        "Migrating the test database...".log(terminator: "")
        try service.execute(".build/debug/\(executable.name) \(environment.configuration) --test db migrate")
        "done".log(as: .good)

        "Testing.......................".log(terminator: "")
        try service.execute(swift: "test")
        "done".log(as: .good)

        "Building for release..........".log(terminator: "")
        try service.execute(swift: "build -c release")
        "done".log(as: .good)

        "Migrating the database........".log(terminator: "")
        try service.execute(".build/release/\(executable.name) \(environment.configuration) db migrate")
        "done".log(as: .good)

        try service.change(to: nil)

        "Replacing install.............".log(terminator: "")

        try service.execute("cp -Trf \(tempDirectory) \(finalDirectory)")
        try service.execute("rm -r \(tempDirectory)")
        "done".log(as: .good)

        "Restaring  the service........".log(terminator: "")
        try service.execute("sudo service \(environment.remoteServicePrefix)\(spec.domain) restart")
        "done".log(as: .good)

        "----------------------------------".log()
        "Deployed Successfully".log(as: .good)
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
