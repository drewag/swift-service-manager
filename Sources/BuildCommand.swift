//
//  BuildCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

import CommandLineParser
import SwiftPlusPlus

struct BuildCommand {
    static func handler(parser: Parser) throws {
        let environment = parser.optionalString(named: "environment")
        try parser.parse()

        let service = try PackageService()
        try service.build(for: environment.parsedValue == "prod" ? .release : .debug)
    }
}

extension PackageService {
    func build(for environment: Environment) throws {
        var flags = "-Xcc -I/usr/local/include -Xlinker -L/usr/local/lib/ -Xcc -I/usr/local/include/libxml2"
        flags.append(" --configuration \(environment.rawValue)")
        "Building for \(environment.rawValue)...".log()
        let _ = try ShellCommand("swift build \(flags)", captureOutput: false).execute()
    }
}
