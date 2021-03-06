//
//  EditCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/21/17.
//
//

import Foundation
import CommandLineParser
import Swiftlier
import SwiftlierCLI

struct EditCommand: CommandHandler {
    static let name: String = "edit"
    static let shortDescription: String? = "Pull down the web service repositry at the given URL to edit it"
    static let longDescription: String? = "Pull down the web service repositry at the given URL, build it, setup the datbabase locally, and open the project in Xcode"

    static func handler(parser: Parser) throws {
        let repository = parser.url(named: "git_repository_url")

        try parser.parse()

        do {
            try ShellCommand("git status").execute()
        }
        catch {
            let url = repository.parsedValue
            "Cloning repository...".log()
            try ShellCommand("git clone \(repository.parsedValue.absoluteString)").execute()
            guard FileManager.default.changeCurrentDirectoryPath(url.deletingPathExtension().lastPathComponent) else {
                throw GenericSwiftlierError("editing repository", because: "Couldn't change directory into repository", byUser: true)
            }

            var service = PackageService(executableName: nil)
            try service.resetDatabase(for: .debug, includingRole: true, includingMigration: true)
            try service.generateProject(noBuild: false)
            try service.openProject()

            return
        }
        throw GenericSwiftlierError("editing repository", because: "Trying to edit inside an existing repository", byUser: true)
    }
}
