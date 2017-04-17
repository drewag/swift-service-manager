//
//  ProjectCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

import CommandLineParser
import SwiftPlusPlus

struct ProjectCommand: CommandHandler {
    static let name: String = "project"
    static let shortDescription: String? = "Generate an Xcode project and open it"
    static let longDescription: String? = nil

    static func handler(parser: Parser) throws {
        try parser.parse()

        var service = try PackageService()
        try service.generateAndOpenProject()
    }
}

extension PackageService {
    mutating func generateAndOpenProject() throws {
        "Generating project...".log()
        try self.generateProject()
        try self.generateSchemes()
        try self.openProject()
    }
}

private extension PackageService {
    func generateProject() throws {
        let flags = self.buildFlags
        let _ = try ShellCommand("swift package \(flags) generate-xcodeproj").execute()
    }

    func openProject() throws {
        print("Openning project...")
        let _ = try ShellCommand("open \(self.name).xcodeproj").execute()
    }

    mutating func generateSchemes() throws {
        try self.schemeXML(arguments: ["server", "8080"])
            .write(toFile: "\(name).xcodeproj/xcshareddata/xcschemes/server.xcscheme", atomically: true, encoding: .utf8)
        try self.schemeXML(arguments: ["info"])
            .write(toFile: "\(name).xcodeproj/xcshareddata/xcschemes/info.xcscheme", atomically: true, encoding: .utf8)
        try self.schemeXML(arguments: ["db", "migrate"])
            .write(toFile: "\(name).xcodeproj/xcshareddata/xcschemes/migrate-database.xcscheme", atomically: true, encoding: .utf8)
        for scheme in try self.loadSpec(for: .debug).extraSchemes {
            let name = scheme.name.lowercased().replacingOccurrences(of: " ", with: "-")
            try self.schemeXML(arguments: scheme.arguments)
                .write(toFile: "\(self.name).xcodeproj/xcshareddata/xcschemes/\(name).xcscheme", atomically: true, encoding: .utf8)
        }
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
