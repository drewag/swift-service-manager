//
//  RunCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/21/17.
//
//

import Foundation
import CommandLineParser
import Swiftlier
import SwiftlierCLI

struct RunCommand: CommandHandler {
    static let name: String = "run"
    static let shortDescription: String? = "Start running a server"
    static let longDescription: String? = "Start running a server on the specified port for the given configuration (prod|debug - defaults to debug)"

    static func handler(parser: Parser) throws {
        let port = parser.optionalInt(named: "port")
        let environment = parser.optionalString(named: "configuration")
        let executable = parser.optionalString(named: "executable")

        try parser.parse()

        var service = PackageService(executableName: executable.parsedValue)
        try service.run(onPort: port.parsedValue, for: environment.parsedValue == "prod" ? .release : .debug)
    }
}

var commandToKill: ShellCommand?

extension PackageService {
    mutating func run(onPort port: Int?, for environment: Environment) throws {
        try self.command(named: "Staring server...", captureOutput: true, for: environment, subCommand: "server \(port ?? 8080)").execute()
    }
}
