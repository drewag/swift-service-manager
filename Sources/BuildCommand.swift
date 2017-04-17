//
//  BuildCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

import CommandLineParser
import SwiftPlusPlus

struct BuildCommand: CommandHandler {
    static let name: String = "build"
    static let shortDescription: String? = "Rebuild the passed in configuration (prod|debug - defaults to debug)"
    static let longDescription: String? = nil

    static func handler(parser: Parser) throws {
        let environment = parser.optionalString(named: "configuration")
        try parser.parse()

        let service = try PackageService()
        try service.build(for: environment.parsedValue == "prod" ? .release : .debug)
    }
}

extension PackageService {
    func build(for environment: Environment) throws {
        var flags = self.buildFlags
        flags.append(" --configuration \(environment.rawValue)")
        "Building for \(environment.rawValue)...".log()
        let _ = try ShellCommand("swift build \(flags)", captureOutput: false).execute()
    }
}
