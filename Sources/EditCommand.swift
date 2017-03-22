//
//  EditCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/21/17.
//
//

import Foundation
import CommandLineParser
import SwiftPlusPlus

struct EditCommand {
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
                throw LocalUserReportableError(source: "EditCommand", operation: "editing repository", message: "Couldn't change directory into repository", reason: .user)
            }

            var service = try PackageService()
            try service.resetDatabase()
            try service.generateAndOpenProject()

            return
        }
        throw LocalUserReportableError(source: "EditCommand", operation: "editing repository", message: "Trying to edit inside an existing repository", reason: .user)
    }
}

extension PackageService {
}
