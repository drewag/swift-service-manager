import CommandLineParser

let parser = Parser(arguments: CommandLine.arguments)

parser.command(named: "init", handler: InitCommand.handler)
parser.command(named: "build", handler: BuildCommand.handler)
parser.command(named: "project", handler: ProjectCommand.handler)
parser.command(named: "db", handler: DatabaseCommand.handler)

do {
    try parser.parse()
}
catch {
    "\(error)".log(as: .bad)
}
