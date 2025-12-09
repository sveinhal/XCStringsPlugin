import PackagePlugin
import Foundation

enum PluginError: Error, CustomStringConvertible {
    case toolNotFound
    case notSupportedOnThisPlatform

    var description: String {
        switch self {
        case .toolNotFound:
            return "Could not locate 'xcstringstool' via xcrun."
        case .notSupportedOnThisPlatform:
            return "xcstringstool-based plugin only works on macOS with Xcode installed."
        }
    }
}

@main
struct GenerateSymbolsPlugin: BuildToolPlugin {

    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) throws -> [Command] {

        #if canImport(XcodeProjectPlugin)
        // When building from Xcode, use STRING_CATALOG_GENERATE_SYMBOLS
        return []
        #elseif !os(macOS)
        // When building on Linux or other platforms, throw an error
        throw PluginError.notSupportedOnThisPlatform
        #else

        // Bare SourceModuleTargets har filer
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        // Finn alle .xcstrings i targetet
        let xcstringsFiles = sourceTarget.sourceFiles(withSuffix: "xcstrings")
        guard !xcstringsFiles.isEmpty else {
            return []
        }

        // Output-katalog for generert Swift
        let outputDir = context.pluginWorkDirectoryURL.appending(path: "GeneratedStrings")
        try FileManager.default.createDirectory(
            atPath: outputDir.path(),
            withIntermediateDirectories: true
        )

        // Finn sti til xcstringstool via xcrun
        let xcstringstoolPath = try findXcstringsTool()

        // Lag én build-kommando per .xcstrings
        return xcstringsFiles.map { file in
            let baseName = file.url.deletingPathExtension().lastPathComponent
            return .buildCommand(
                displayName: "Generate symbols for \(file.url.lastPathComponent)",
                executable: xcstringstoolPath,
                arguments: [
                    "generate-symbols",
                    file.url.path(),
                    "--output-directory", outputDir.path(),
                    "--language", "swift"
                ],
                inputFiles: [file.url],
                outputFiles: [outputDir.appending(path: "GeneratedStringSymbols_\(baseName).swift")]
            )
        }
        #endif
    }

    private func findXcstringsTool() throws -> URL {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["-f", "xcstringstool"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0,
              let data = try? pipe.fileHandleForReading.readToEnd(),
              let string = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !string.isEmpty
        else {
            throw PluginError.toolNotFound
        }

        return URL(filePath: string)
    }
}
