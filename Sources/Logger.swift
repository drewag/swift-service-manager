//
//  Logger.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/21/17.
//
//

class Logger {
    enum LogType: Int {
        case normal = 0
        case bad = 31
        case good = 32
        case neutral = 34
    }

    static func log(_ string: String, type: LogType = .neutral) {
        let prefix: String
        let suffix: String
        switch type {
        case .normal:
            prefix = ""
            suffix = ""
        default:
            prefix = "\u{001B}[0;\(type.rawValue)m"
            suffix = "\u{001B}[m"
        }
        print("\(prefix)\(string)\(suffix)")
    }
}

extension String {
    func log(as type: Logger.LogType = .neutral) {
        Logger.log(self, type: type)
    }
}
