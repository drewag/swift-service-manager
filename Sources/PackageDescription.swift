//
//  PackageDescription.swift
//  ssm
//
//  Created by Andrew J Wagner on 11/30/18.
//

import Foundation

struct PackageDescription: Decodable {
    let name: String
    let path: String
    let targets: [PackageTarget]

    var executables: [PackageTarget] {
        return self.targets.filter({$0.type == .executable})
    }
}

struct PackageTarget: Decodable {
    enum Kind: String, Decodable {
        case executable
        case library
        case test

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            let raw = try container.decode(String.self)
            guard let actual = Kind(rawValue: raw) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized executable type found: '\(raw)'")
            }
            self = actual
        }
    }

    let name: String
    let type: Kind
}
