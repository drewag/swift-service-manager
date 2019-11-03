//
//  DeployCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 11/30/18.
//

import Foundation
import CommandLineParser
import Swiftlier
import SwiftlierCLI

struct DeployCommand: CommandHandler {
    static let name: String = "deploy"
    static let shortDescription: String? = "Deploy to a server"
    static let longDescription: String? = nil

    static func handler(parser: Parser) throws {
        let environmentPromise = parser.string(named: "configuration")
        let executable = parser.optionalString(named: "executable")
        let resume = parser.option(named: "resume")

        try parser.parse()

        var packageService = PackageService(executableName: executable.parsedValue)
        try packageService.deploy(environmentPromise.parsedValue == "prod" ? .release : .debug, resume: resume.wasPresent)
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

    mutating func deploy(_ environment: Environment, resume: Bool) throws {
        if !resume {
            do {
                try ShellCommand("git diff-index --quiet HEAD --").execute()
            }
            catch {
                throw GenericSwiftlierError("deploying", because: "you have uncommited changes", byUser: true)
            }

            try ShellCommand("git fetch").execute()
            let count = try ShellCommand("git rev-list --count origin/master..master").execute().chomp()
            guard count == "0" else {
                throw GenericSwiftlierError("deploying", because: "you have unpushed commits", byUser: true)
            }
        }

        let executable = try self.executable()

        let spec = try self.loadSpec(for: .release) // Always build from prod because that is what will be used on the server
        let description = try self.loadDescription()

        if !resume {
            try self.test()
        }

        "Deploying \(environment.name)...".log()
        "----------------------------------".log()

        let repository = try ShellCommand("git config --get remote.origin.url").execute().chomp()

        var service = try RemoteServerService(host: spec.deployDomain)
        let tempDirectory = "\(environment.remoteTempDirectoryPrefix)\(spec.domain)"
        let finalDirectory = "\(environment.remoteDirectoryPrefix)\(spec.domain)"

        if !resume {
            "Cloning latest code...........".log(terminator: "")
            try service.execute("rm -r \(tempDirectory) || true")
            try service.execute("ssh-agent bash -c 'ssh-add ~/.ssh/\(spec.domain); git clone \(repository) \(tempDirectory)'")
            try service.execute("mkdir -p \(finalDirectory)/Config")
            try service.execute("mkdir -p \(tempDirectory)/Config")
            try service.execute("cp \(finalDirectory)/Config/* \(tempDirectory)/Config")
            "done".log(as: .good)

            "Copying data directories......".log(terminator: "")
            for directory in spec.dataDirectories {
                try service.execute("ln -s \(finalDirectory)/\(directory) \(tempDirectory)/\(directory)")
            }
            "done".log(as: .good)
        }

        try service.change(to: tempDirectory)

        "Updating packages.............".log(terminator: "")
        try service.execute(swift: "package update")
        "done".log(as: .good)

        "Building for debug............".log(terminator: "")
        let extraFlagsCommand = "[ -r extra_linux_build_flags.txt ] && cat extra_linux_build_flags.txt"
        try service.execute(swift: "build `\(extraFlagsCommand)`")
        "done".log(as: .good)

        "Generating files..............".log(terminator: "")
        try service.execute(".build/debug/\(executable.name) \(environment.configuration) regenerate https://\(environment.remoteServicePrefix)\(spec.domain)")
        "done".log(as: .good)

        "Migrating the test database...".log(terminator: "")
        for executable in description.executables {
            try service.execute(".build/debug/\(executable.name) \(environment.configuration) --test db migrate")
        }
        "done".log(as: .good)

        "Testing.......................".log(terminator: "")
        try service.execute(swift: "test `\(extraFlagsCommand)`")
        "done".log(as: .good)

        "Building for release..........".log(terminator: "")
        try service.execute(swift: "build -c release `\(extraFlagsCommand)`")
        "done".log(as: .good)

        "Migrating the database........".log(terminator: "")
        try service.execute(".build/release/\(executable.name) \(environment.configuration) db migrate")
        "done".log(as: .good)

        "Installing....................".log(terminator: "")
        try service.execute("rm -rf \(finalDirectory)/Generated")
        try service.execute("cp -rp \(tempDirectory)/Generated \(finalDirectory)")
        try service.execute("rm -rf \(finalDirectory)/.build")
        try service.execute("mkdir -p \(finalDirectory)/.build/release/")
        try service.execute("cp -rp \(tempDirectory)/.build/release/\(executable.name) \(finalDirectory)/.build/release/")
        try service.change(to: finalDirectory)
        try service.execute("ssh-agent bash -c 'ssh-add ~/.ssh/\(spec.domain); git pull'")
        "done".log(as: .good)

        "Restaring  the service........".log(terminator: "")
        try service.execute("sudo service \(environment.remoteServicePrefix)\(spec.domain) restart")
        try service.execute("rm -rf \(tempDirectory)")
        "done".log(as: .good)

        if !spec.extraDeployDomains.isEmpty {
            "Deploying to extra deploy domains".log()

            let binaryPath = "/tmp/\(spec.domain).binary"
            try ShellCommand("scp \(spec.deployDomain):\(finalDirectory)/.build/release/\(executable.name) \(binaryPath)").execute()

            for domain in spec.extraDeployDomains {
                "\(domain)...".log(terminator: "")

                let domainService = try RemoteServerService(host: domain)

                try ShellCommand("scp \(binaryPath) \(domain):\(binaryPath)").execute()
                try domainService.execute("sudo service \(environment.remoteServicePrefix)\(spec.domain) stop")
                try domainService.execute("cp -rp \(binaryPath) \(finalDirectory)/.build/release/\(executable.name)")
                try domainService.execute("sudo service \(environment.remoteServicePrefix)\(spec.domain) start")

                "done".log(as: .good)
            }
        }

        "----------------------------------".log()
        "Deployed Successfully".log(as: .good)
    }
}
