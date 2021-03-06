//
//  PackageService.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

import SwiftServe
import Swiftlier
import Foundation
import SwiftlierCLI

struct PackageService {
    private var builtEnvironments = [Environment:Void]()
    fileprivate var spec: SwiftServeInstanceSpec? = nil
    fileprivate var desc: PackageDescription? = nil

    let executableName: String?
    init(executableName: String?) {
        self.executableName = executableName
    }

    mutating func name() throws -> String {
        return try self.loadDescription().name
    }

    mutating func executable() throws -> PackageTarget {
        let description = try self.loadDescription()
        if let name = self.executableName {
            guard let executable = description.executables.first(where: {$0.name == name}) else {
                throw GenericSwiftlierError("executing", because: "an executable named '\(name)' could not be found", byUser: true)
            }
            return executable
        }
        else {
            guard description.executables.count <= 1 else {
                throw GenericSwiftlierError("executing", because: "multiple executables were found, you must specify which one should be used", byUser: true)
            }
            guard let executable = description.executables.first else {
                throw GenericSwiftlierError("executing", because: "no executable found", byUser: true)
            }
            return executable
        }
    }

    var buildFlags: String {    
        var flags = ""
        #if os(macOS)
            let extraFlags = ((try? FileSystem.default.workingDirectory.file("extra_mac_build_flags.txt").file?.string()) ?? "") ?? ""
        #elseif os(Linux)
            let extraFlags = ((try? FileSystem.default.workingDirectory.file("extra_linux_build_flags.txt").file?.string()) ?? "") ?? ""
        #else
            let extraFlags = ""
        #endif
        if !extraFlags.isEmpty {
            flags += " " + extraFlags.chomp()
        }
        return flags
    }

    mutating func loadDescription() throws -> PackageDescription {
        if let desc = self.desc {
            return desc
        }

        let json = try ShellCommand("swift package describe --type json").execute()
        let data = json.data(using: .utf8) ?? Data()
        return try JSONDecoder().decode(PackageDescription.self, from: data)
    }

    mutating func loadSpec(for environment: Environment) throws -> SwiftServeInstanceSpec {
        if let spec = self.spec {
            return spec
        }

        if self.builtEnvironments[environment] == nil {
            try self.build(for: environment)
            self.builtEnvironments[environment] = ()
        }

        let spec = try self.validateSpec(for: environment)
        self.spec = spec
        return spec
    }

    mutating func command(named: String? = nil, captureOutput: Bool = false, for environment: Environment = .debug, subCommand: String) throws -> ShellCommand {
        if self.builtEnvironments[environment] == nil {
            try self.build(for: environment)
            self.builtEnvironments[environment] = ()
        }

        // Force spec validation
        let _ = try self.loadSpec(for: environment)

        named?.log(as: .neutral)
        return ShellCommand(".build/\(environment.rawValue)/\(try self.executable().name) \(environment.configuration) \(subCommand)", captureOutput: captureOutput)
    }

    @discardableResult
    mutating func call(named: String? = nil, captureOutput: Bool = false, subCommand: String, for environment: Environment = .release) throws -> String {
        return try self.command(named: named, captureOutput: captureOutput, for: environment, subCommand: subCommand).execute()
    }
}

private extension PackageService {
    mutating func validateSpec(for environment: Environment) throws -> SwiftServeInstanceSpec {
        let jsonString = try ShellCommand(".build/\(environment.rawValue)/\(try self.executable().name) info").execute()
        let data = jsonString.data(using: .utf8)!
        let spec = try JSONDecoder().decode(SwiftServeInstanceSpec.self, from: data)

        guard spec.version.major == 5 else {
            throw GenericSwiftlierError("validating service spec", because: "Incorrect version", byUser: true)
        }

        if !FileManager.default.fileExists(atPath: "extra_info.json") && !FileManager.default.fileExists(atPath: "Config/extra_info.json") {
            guard let extraInfoDict = try JSONSerialization.jsonObject(with: spec.extraInfoSpec.data(using: .utf8)!, options: JSONSerialization.ReadingOptions()) as? [String:String] else {
                throw GenericSwiftlierError("validating service spec", because: "Unrecognized extra info format", byUser: true)
            }

            if extraInfoDict.count > 0 {
                "Extra Info Required for this Service:".log()
                var output = [String:Any]()
                for (key, type) in extraInfoDict {
                    output[key] = try self.value(for: key, andType: type)
                }

                let data = try JSONSerialization.data(withJSONObject: output, options: .prettyPrinted)
                try data.write(to: URL(fileURLWithPath: "extra_info.json"), options: .atomic)
            }
        }

        return spec
    }

    func value(for key: String, andType type: String) throws -> Any {
        var type = type
        let isOptional = type.hasSuffix("?")
        if isOptional {
            type = String(type[...type.index(at: type.count - 1)])
        }

        var input: String = ""
        repeat {
            print("\(key)? ", terminator: "")
            input = readLine(strippingNewline: true) ?? ""

            if input.isEmpty {
                if isOptional {
                    return NSNull()
                }
                else {
                    print("Value is required")
                    continue
                }
            }

            switch type {
            case "string":
                return input
            case "bool":
                return (input == "y" || input == "yes")
            case "int":
                guard let int = Int(input) else {
                    print("Must be an integer")
                    continue
                }
                return int
            case "double":
                guard let double = Double(input) else {
                    print("Must be a decimal")
                    continue
                }
                return double
            case "float":
                guard let float = Float(input) else {
                    print("Must be an decimal")
                    continue
                }
                return float
            case "data":
                return input.data(using: .utf8)!
            case "date":
                guard let value = input.date ?? input.railsDateTime ?? input.railsDate ?? input.iso8601DateTime else {
                    print("Invalid date/time")
                    continue
                }
                return value
            default:
                throw GenericSwiftlierError("validating service spec", because: "Unreconized type: \(type)", byUser: true)
            }
        } while input.isEmpty

        fatalError("Should not reach here")
    }
}

extension String {
    /// Removes a single trailing newline if the string has one.
    func chomp() -> String {
        if self.hasSuffix("\n") {
            return String(self[self.startIndex ..< self.index(before: self.endIndex)])
        } else {
            return self
        }
    }
}
