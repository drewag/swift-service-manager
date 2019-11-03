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

struct Testcommand: CommandHandler {
    static let name: String = "test"
    static let shortDescription: String? = "Run tests"
    static let longDescription: String? = nil

    static func handler(parser: Parser) throws {
        try parser.parse()

        let service = PackageService(executableName: nil)
        try service.test()
    }
}

extension PackageService {
    func test() throws {
        let flags = self.buildFlags
        "Testing...".log()
        try ShellCommand("swift test \(flags)", captureOutput: false).execute()
    }
}
