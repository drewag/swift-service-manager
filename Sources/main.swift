import Foundation
import CommandLineParser

guard validateDependencies() else {
    exit(1)
}

let parser = Parser(arguments: CommandLine.arguments)

//parser.command(InitCommand.self)
parser.command(BuildCommand.self)
parser.command(Testcommand.self)
parser.command(ProjectCommand.self)
parser.command(DatabaseCommand.self)
parser.command(EditCommand.self)
parser.command(RunCommand.self)
parser.command(UpdateCommand.self)
parser.command(CustomCommand.self)
parser.command(DeployCommand.self)

do {
    try parser.parse()
}
catch {
    "\(error)".log(as: .bad)
    exit(1)
}
