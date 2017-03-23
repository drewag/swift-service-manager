//
//  PackageService.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

import SwiftServe
import SwiftPlusPlus
import Foundation

struct PackageService {
    enum Environment: String {
        case release
        case debug
    }

    let name: String
    private var builtEnvironments = [Environment:Void]()
    fileprivate var spec: SwiftServeInstanceSpec? = nil

    var databaseName: String {
        return self.name.replacingOccurrences(of: ".", with: "_")
    }

    init() throws {
        self.name = try type(of: self).getPackageName()
    }

    mutating func loadSpec(for environment: Environment) throws -> SwiftServeInstanceSpec {
        if let spec = self.spec {
            return spec
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
        return ShellCommand(".build/\(environment.rawValue)/\(self.name) \(subCommand)", captureOutput: !captureOutput)
    }

    mutating func queryDatabaseCommand(with query: String) -> ShellCommand {
        return ShellCommand("echo \(query)").pipe(to: "psql -d \(self.databaseName)", captureOutput: false)
    }

    @discardableResult
    mutating func call(named: String? = nil, captureOutput: Bool = false, subCommand: String, for environment: Environment = .release) throws -> String {
        return try self.command(named: named, captureOutput: captureOutput, for: environment, subCommand: subCommand).execute()
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

    mutating func validateSpec(for environment: Environment) throws -> SwiftServeInstanceSpec {
        let jsonString = try ShellCommand(".build/\(environment.rawValue)/\(self.name) info").execute()
        let object = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: JSONSerialization.ReadingOptions())
        let spec: SwiftServeInstanceSpec = try NativeTypesDecoder.decodableTypeFromObject(object, mode: .saveLocally)

        guard spec.version.major == 5 else {
            throw LocalUserReportableError(source: "PackageService", operation: "validating service spec", message: "Incorrect version", reason: .user)
        }

        if !FileManager.default.fileExists(atPath: "extra_info.json") {
            guard let extraInfoDict = try JSONSerialization.jsonObject(with: spec.extraInfoSpec.data(using: .utf8)!, options: JSONSerialization.ReadingOptions()) as? [String:String] else {
                throw LocalUserReportableError(source: "PackageService", operation: "validating service spec", message: "Unrecognized extra info format", reason: .user)
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
            type = type.substring(to: type.characters.count - 1)
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
                throw LocalUserReportableError(source: "PackageService", operation: "validating service spec", message: "Unreconized type: \(type)", reason: .user)
            }
        } while input.isEmpty

        fatalError("Should not reach here")
    }
}
