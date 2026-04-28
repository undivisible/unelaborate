import Foundation

actor ModpackExportService {
    func exportMrpack(instance: MinecraftInstance, destination: URL) throws {
        let exportRoot = FileManager.default.temporaryDirectory.appendingPathComponent("unelaborate-export-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: exportRoot, withIntermediateDirectories: true)

        let files = try (FileManager.default.contentsOfDirectory(at: instance.modsDirectory, includingPropertiesForKeys: nil))
            .filter { $0.pathExtension == "jar" }
            .map {
                MrpackFile(path: "mods/\($0.lastPathComponent)", hashes: [:], downloads: [], fileSize: 0)
            }

        let index = MrpackIndex(
            formatVersion: 1,
            game: "minecraft",
            versionID: instance.name,
            name: instance.name,
            summary: "Exported from Unelaborate",
            files: files,
            dependencies: ["minecraft": instance.mcVersion]
        )

        let indexData = try JSONEncoder.pretty.encode(index)
        let indexPath = exportRoot.appendingPathComponent("modrinth.index.json")
        try indexData.write(to: indexPath)

        let final = destination.appendingPathExtension("mrpack")
        if FileManager.default.fileExists(atPath: final.path) {
            try FileManager.default.removeItem(at: final)
        }
        try archive(exportRoot: exportRoot, destination: final)
    }

    private func archive(exportRoot: URL, destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = exportRoot
        process.arguments = ["-r", destination.path, "modrinth.index.json"]

        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "ModpackExportService", code: Int(process.terminationStatus))
        }
    }
}

private struct MrpackIndex: Codable {
    let formatVersion: Int
    let game: String
    let versionID: String
    let name: String
    let summary: String
    let files: [MrpackFile]
    let dependencies: [String: String]

    enum CodingKeys: String, CodingKey {
        case formatVersion = "formatVersion"
        case game
        case versionID = "versionId"
        case name
        case summary
        case files
        case dependencies
    }
}

private struct MrpackFile: Codable {
    let path: String
    let hashes: [String: String]
    let downloads: [String]
    let fileSize: Int

    enum CodingKeys: String, CodingKey {
        case path
        case hashes
        case downloads
        case fileSize = "fileSize"
    }
}
