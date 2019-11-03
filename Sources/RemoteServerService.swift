//
//  RemoteServerService.swift
//  ssm
//
//  Created by Andrew J Wagner on 11/30/18.
//

import Foundation
import Swiftlier
import SwiftlierCLI
import Shout

struct RemoteServerService {
    let ssh: SSH
    var workingDirectory: String?

    init(host: String, username: String? = nil, privateKey: String = "~/.ssh/id_rsa") throws {
        let actualUsername: String
        if let username = username {
            actualUsername = username
        }
        else {
            actualUsername = try ShellCommand("whoami").execute().chomp()
        }
        self.ssh = try SSH(host: host)
        try self.ssh.authenticate(username: actualUsername, privateKey: privateKey)
    }

    mutating func change(to directory: String?) throws {
        guard let directory = directory else {
            self.workingDirectory = nil
            return
        }

        do {
            try self.execute("if [ ! -d '\(directory)' ]; then false; fi")
            self.workingDirectory = directory
        }
        catch {
            throw GenericSwiftlierError("changing to directory", because: "'\(directory)' could not be found.")
        }
    }

    @discardableResult
    func execute(_ command: String, capture: Bool = true) throws -> String {
        var command = command
        if let directory = self.workingDirectory {
            command = "cd \(directory) && \(command)"
        }
        let (status, output) = try self.ssh.capture(command)
        switch status {
        case 0:
            return output
        default:
            throw GenericSwiftlierError("executing '\(command)'", because: "It returned status \(status). It returned '\(output)'")
        }
    }

    @discardableResult func execute(swift: String) throws -> String {
        return try self.execute("/usr/bin/swiftenv/versions/`if [[ -f .swift-version ]]; then cat .swift-version; else echo 5.1.1; fi`/usr/bin/swift \(swift)")
    }
}
