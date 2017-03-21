//
//  ProjectCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

import CommandLineParser
import SwiftPlusPlus

struct ProjectCommand {
    static func handler(parser: Parser) throws {
        try parser.parse()

        let service = try PackageService()

        try service.generateProject()
        try service.generateSchemes()
        try service.openProject()
    }
}

private extension PackageService {
    func generateProject() throws {
        print("Generating project...")
        let flags = "-Xcc -I/usr/local/include -Xlinker -L/usr/local/lib/ -Xswiftc -I/usr/local/include"
        let _ = try ShellCommand("swift package generate-xcodeproj \(flags)").execute()
    }

    func openProject() throws {
        print("Openning project...")
        let _ = try ShellCommand("open \(self.name).xcodeproj").execute()
    }

    func generateSchemes() throws {
        try self.schemeXML(arguments: ["server", "8080"])
            .write(toFile: "\(name).xcodeproj/xcshareddata/xcschemes/server.xcscheme", atomically: true, encoding: .utf8)
        try self.schemeXML(arguments: ["info"])
            .write(toFile: "\(name).xcodeproj/xcshareddata/xcschemes/info.xcscheme", atomically: true, encoding: .utf8)
        try self.schemeXML(arguments: ["db", "migrate"])
            .write(toFile: "\(name).xcodeproj/xcshareddata/xcschemes/migrate-database.xcscheme", atomically: true, encoding: .utf8)
    }

    func schemeXML(arguments: [String]) -> String {
        let projectName = "\(self.name).xcodeproj"
        var xml = ""
        xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        xml += "<Scheme LastUpgradeVersion = \"0810\" version = \"1.3\">"
        xml += "<BuildAction parallelizeBuildables = \"YES\" buildImplicitDependencies = \"YES\">"
        xml += "    <BuildActionEntries>"
        xml += "        <BuildActionEntry buildForTesting = \"YES\" buildForRunning = \"YES\" buildForProfiling = \"YES\" buildForArchiving = \"YES\" buildForAnalyzing = \"YES\">"
        xml += "            <BuildableReference  BuildableIdentifier = \"primary\" BlueprintIdentifier = \"OBJ_1045\" BuildableName = \"\(self.name)\" BlueprintName = \"\(self.name)\" ReferencedContainer = \"container:\(projectName)\">"
        xml += "            </BuildableReference>"
        xml += "        </BuildActionEntry>"
        xml += "    </BuildActionEntries>"
        xml += "</BuildAction>"
        xml += "<TestAction buildConfiguration = \"Debug\" selectedDebuggerIdentifier = \"Xcode.DebuggerFoundation.Debugger.LLDB\" selectedLauncherIdentifier = \"Xcode.DebuggerFoundation.Launcher.LLDB\" shouldUseLaunchSchemeArgsEnv = \"YES\">"
        xml += "    <Testables></Testables>"
        xml += "    <MacroExpansion>"
        xml += "        <BuildableReference BuildableIdentifier = \"primary\" BlueprintIdentifier = \"OBJ_1045\" BuildableName = \"\(self.name)\" BlueprintName = \"\(self.name)\" ReferencedContainer = \"container:\(projectName)\">"
        xml += "        </BuildableReference>"
        xml += "    </MacroExpansion>"
        xml += "    <AdditionalOptions></AdditionalOptions>"
        xml += "</TestAction>"
        xml += "<LaunchAction buildConfiguration = \"Debug\" selectedDebuggerIdentifier = \"Xcode.DebuggerFoundation.Debugger.LLDB\" selectedLauncherIdentifier = \"Xcode.DebuggerFoundation.Launcher.LLDB\" launchStyle = \"0\" useCustomWorkingDirectory = \"YES\" customWorkingDirectory = \"$(PROJECT_DIR)\" ignoresPersistentStateOnLaunch = \"NO\" debugDocumentVersioning = \"YES\" debugServiceExtension = \"internal\" allowLocationSimulation = \"YES\">"
        xml += "    <BuildableProductRunnable runnableDebuggingMode = \"0\">"
        xml += "        <BuildableReference BuildableIdentifier = \"primary\" BlueprintIdentifier = \"OBJ_1045\" BuildableName = \"\(self.name)\" BlueprintName = \"\(self.name)\" ReferencedContainer = \"container:\(projectName)\">"
        xml += "        </BuildableReference>"
        xml += "    </BuildableProductRunnable>"
        xml += "    <CommandLineArguments>"
        for argument in arguments {
            xml += "        <CommandLineArgument argument = \"\(argument)\" isEnabled = \"YES\"></CommandLineArgument>"
        }
        xml += "    </CommandLineArguments>"
        xml += "    <AdditionalOptions></AdditionalOptions>"
        xml += "</LaunchAction>"
        xml += "<ProfileAction buildConfiguration = \"Release\" shouldUseLaunchSchemeArgsEnv = \"YES\" savedToolIdentifier = \"\" useCustomWorkingDirectory = \"NO\" debugDocumentVersioning = \"YES\">"
        xml += "    <BuildableProductRunnable runnableDebuggingMode = \"0\">"
        xml += "        <BuildableReference BuildableIdentifier = \"primary\" BlueprintIdentifier = \"OBJ_1045\" BuildableName = \"\(self.name)\" BlueprintName = \"\(self.name)\" ReferencedContainer = \"container:\(projectName)\">"
        xml += "        </BuildableReference>"
        xml += "    </BuildableProductRunnable>"
        xml += "</ProfileAction>"
        xml += "<AnalyzeAction buildConfiguration = \"Debug\"></AnalyzeAction>"
        xml += "<ArchiveAction buildConfiguration = \"Release\" revealArchiveInOrganizer = \"YES\"></ArchiveAction>"
        xml += "</Scheme>"
        return xml
    }
}
