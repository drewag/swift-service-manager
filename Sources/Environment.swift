//
//  Environment.swift
//  ssm
//
//  Created by Andrew J Wagner on 11/30/18.
//

import SwiftServe

enum Environment: String {
    case release
    case debug

    var serviceEnvironment: SwiftServiceEnvironment {
        switch self {
        case .release:
            return .production
        case .debug:
            return .development
        }
    }

    var name: String {
        switch self {
        case .release:
            return "Production"
        case .debug:
            return "Development"
        }
    }

    var configuration: String {
        switch self {
        case .debug:
            return "--dev"
        case .release:
            return "--prod"
        }
    }

    var remoteTempDirectoryPrefix: String {
        return "/tmp/\(self.remoteServicePrefix)"
    }

    var remoteDirectoryPrefix: String {
        return "/var/www/\(self.remoteServicePrefix)"
    }

    var remoteServicePrefix: String {
        switch self {
        case .debug:
            return "dev."
        case .release:
            return ""
        }
    }
}
