//
//  PackageService.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

import SwiftPlusPlus

struct PackageService {
    enum Environment: String {
        case release
        case debug
    }

    let name: String
    private var builtEnvironments = [Environment:Void]()

    init() throws {
        self.name = try type(of: self).getPackageName()
    }

    mutating func command(for environment: Environment = .release, subCommand: String) throws -> ShellCommand {
        if self.builtEnvironments[environment] == nil {
            try self.build(for: environment)
            self.builtEnvironments[environment] = ()
        }

        return ShellCommand(".build/\(environment.rawValue)/\(self.name) \(subCommand)")
    }

    @discardableResult
    mutating func call(subCommand: String, for environment: Environment = .release) throws -> String {
        return try self.command(for: environment, subCommand: subCommand).execute()
    }
}

private extension PackageService {
    static func getPackageName() throws -> String {
        let packageJson = try ShellCommand("swift package dump-package").execute()
        guard let jsonData = packageJson.data(using: .utf8)
            , let name = (try JSON(data: jsonData))["name"]?.string
            else
        {
                throw LocalUserReportableError(source: "PackageService", operation: "getting package name", message: "Could not parse package dump", reason: .internal)
        }
        return name
    }
}
