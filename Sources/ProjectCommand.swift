//
//  ProjectCommand.swift
//  ssm
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

import Foundation
import CommandLineParser
import Swiftlier
import SwiftlierCLI

struct ProjectCommand: CommandHandler {
    static let name: String = "project"
    static let shortDescription: String? = "Generate an Xcode project and open it"
    static let longDescription: String? = nil

    static func handler(parser: Parser) throws {
        let noBuild = parser.option(named: "no-build", abbreviatedWith: "n")

        try parser.parse()

        var service = PackageService(executableName: nil)
        try service.generateProject(noBuild: noBuild.wasPresent)
    }
}

extension PackageService {
    mutating func generateProject(noBuild: Bool) throws {
        "Generating project...".log()
        try self.generateProject()
        try self.generateSchemes(noBuild: noBuild)
    }

    mutating func openProject() throws {
        "Openning project...".log()
        let _ = try ShellCommand("open \(try self.name()).xcodeproj").execute()
    }
}

private extension PackageService {
    func generateProject() throws {
        let flags = self.buildFlags
        let _ = try ShellCommand("swift package \(flags) generate-xcodeproj").execute()
    }
    mutating func generateSchemes(noBuild: Bool) throws {
        let name = try self.name()
        try self.schemeXML(arguments: ["server", "8080"], withName: name)
            .write(toFile: "\(name).xcodeproj/xcshareddata/xcschemes/server.xcscheme", atomically: true, encoding: .utf8)
        try self.schemeXML(arguments: ["info"], withName: name)
            .write(toFile: "\(name).xcodeproj/xcshareddata/xcschemes/info.xcscheme", atomically: true, encoding: .utf8)
        try self.schemeXML(arguments: ["db", "migrate"], withName: name)
            .write(toFile: "\(name).xcodeproj/xcshareddata/xcschemes/migrate-database.xcscheme", atomically: true, encoding: .utf8)
        if !noBuild {
            do {
                for scheme in try self.loadSpec(for: .debug).extraSchemes {
                    let name = scheme.name.lowercased().replacingOccurrences(of: " ", with: "-")
                    try self.schemeXML(arguments: scheme.arguments, withName: name)
                        .write(toFile: "\(name).xcodeproj/xcshareddata/xcschemes/\(name).xcscheme", atomically: true, encoding: .utf8)
                }
            }
            catch {
                throw error.swiftlierError(while: "generating extra schemes")
            }
        }
        else {
            "Not generating extra schemes because the no-build option was set".log()
        }
    }

    func schemeXML(arguments: [String], withName name: String) -> String {
        var xml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <Scheme
               LastUpgradeVersion = "0900"
               version = "1.3">
               <BuildAction
                  parallelizeBuildables = "YES"
                  buildImplicitDependencies = "YES">
                  <BuildActionEntries>
                     <BuildActionEntry
                        buildForTesting = "YES"
                        buildForRunning = "YES"
                        buildForProfiling = "YES"
                        buildForArchiving = "YES"
                        buildForAnalyzing = "YES">
                        <BuildableReference
                           BuildableIdentifier = "primary"
                           BlueprintIdentifier = "\(name)::\(name)"
                           BuildableName = "web"
                           BlueprintName = "web"
                           ReferencedContainer = "container:\(name).xcodeproj">
                        </BuildableReference>
                     </BuildActionEntry>
                  </BuildActionEntries>
               </BuildAction>
               <TestAction
                  buildConfiguration = "Debug"
                  selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
                  selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
                  language = ""
                  shouldUseLaunchSchemeArgsEnv = "YES">
                  <Testables>
                  </Testables>
                  <MacroExpansion>
                     <BuildableReference
                        BuildableIdentifier = "primary"
                        BlueprintIdentifier = "\(name)::\(name)"
                        BuildableName = "\(name)"
                        BlueprintName = "\(name)"
                        ReferencedContainer = "container:\(name).xcodeproj">
                     </BuildableReference>
                  </MacroExpansion>
                  <AdditionalOptions>
                  </AdditionalOptions>
               </TestAction>
               <LaunchAction
                  buildConfiguration = "Debug"
                  selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
                  selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
                  language = ""
                  launchStyle = "0"
                  useCustomWorkingDirectory = "YES"
                  customWorkingDirectory = "$(PROJECT_DIR)"
                  ignoresPersistentStateOnLaunch = "NO"
                  debugDocumentVersioning = "YES"
                  debugServiceExtension = "internal"
                  allowLocationSimulation = "YES">
                  <BuildableProductRunnable
                     runnableDebuggingMode = "0">
                     <BuildableReference
                        BuildableIdentifier = "primary"
                        BlueprintIdentifier = "\(name)::\(name)"
                        BuildableName = "\(name)"
                        BlueprintName = "\(name)"
                        ReferencedContainer = "container:\(name).xcodeproj">
                     </BuildableReference>
                  </BuildableProductRunnable>
                  <CommandLineArguments>
            """

        for argument in arguments {
            xml += "        <CommandLineArgument argument = \"\(argument)\" isEnabled = \"YES\"></CommandLineArgument>"
        }

        xml += """
                  </CommandLineArguments>
                  <AdditionalOptions>
                  </AdditionalOptions>
               </LaunchAction>
               <ProfileAction
                  buildConfiguration = "Release"
                  shouldUseLaunchSchemeArgsEnv = "YES"
                  savedToolIdentifier = ""
                  useCustomWorkingDirectory = "NO"
                  debugDocumentVersioning = "YES">
                  <BuildableProductRunnable
                     runnableDebuggingMode = "0">
                     <BuildableReference
                        BuildableIdentifier = "primary"
                        BlueprintIdentifier = "web::web"
                        BuildableName = "web"
                        BlueprintName = "web"
                        ReferencedContainer = "container:web.xcodeproj">
                     </BuildableReference>
                  </BuildableProductRunnable>
               </ProfileAction>
               <AnalyzeAction
                  buildConfiguration = "Debug">
               </AnalyzeAction>
               <ArchiveAction
                  buildConfiguration = "Release"
                  revealArchiveInOrganizer = "YES">
               </ArchiveAction>
            </Scheme>
            """
        return xml
    }
}
