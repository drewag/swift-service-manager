//
//  RunCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/21/17.
//
//

import Foundation
import CommandLineParser
import SwiftPlusPlus

struct RunCommand {
    static func handler(parser: Parser) throws {
        let port = parser.optionalInt(named: "port")

        try parser.parse()

        var service = try PackageService()
        try service.run(onPort: port.parsedValue)
    }
}

var commandToKill: ShellCommand?

extension PackageService {
    mutating func run(onPort port: Int?) throws {
        let command = try self.command(named: "Staring server...", captureOutput: true, for: .debug, subCommand: "server \(port ?? 8080)")
        command.executeAsync()
        commandToKill = command
        signal(SIGINT, { _ in
            commandToKill?.terminate()
        })
        command.waitUntilExit()
    }
}
