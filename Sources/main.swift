import Foundation
import CommandLineParser

guard validateDependencies() else {
    exit(1)
}

let parser = Parser(arguments: CommandLine.arguments)

parser.command(named: "init", handler: InitCommand.handler)
parser.command(named: "build", handler: BuildCommand.handler)
parser.command(named: "project", handler: ProjectCommand.handler)
parser.command(named: "db", handler: DatabaseCommand.handler)
parser.command(named: "edit", handler: EditCommand.handler)
parser.command(named: "run", handler: RunCommand.handler)

do {
    try parser.parse()
}
catch {
    "\(error)".log(as: .bad)
    exit(1)
}
