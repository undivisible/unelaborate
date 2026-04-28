import Foundation

actor ModpackImportService {
    func importMrpack(from source: URL, into rootURL: URL) async throws -> MinecraftInstance {
        let extractDir = FileManager.default.temporaryDirectory.appendingPathComponent("unelaborate-import-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = [source.path, "-d", extractDir.path]
        try process.run()
        process.waitUntilExit()

        let indexPath = extractDir.appendingPathComponent("modrinth.index.json")
        let indexData = try Data(contentsOf: indexPath)
        let index = try JSONDecoder().decode(MrpackIndex.self, from: indexData)

        let name = index.name
        let version = index.dependencies["minecraft"] ?? "1.21.1"
        let loaderString = index.dependencies.keys.first(where: { $0 != "minecraft" }) ?? "vanilla"
        let loader = LoaderType(rawValue: loaderString) ?? .vanilla

        let instanceDir = rootURL.appendingPathComponent("instances").appendingPathComponent(name.replacingOccurrences(of: " ", with: "-").lowercased())
        let mods = instanceDir.appendingPathComponent("mods")
        let resourcepacks = instanceDir.appendingPathComponent("resourcepacks")
        let shaders = instanceDir.appendingPathComponent("shaderpacks")
        try FileManager.default.createDirectory(at: mods, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: resourcepacks, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: shaders, withIntermediateDirectories: true)

        let instance = MinecraftInstance(
            name: name,
            mcVersion: version,
            loader: loader,
            gameDirectory: instanceDir,
            modsDirectory: mods,
            resourcePackDirectory: resourcepacks,
            shaderDirectory: shaders
        )

        try FileManager.default.removeItem(at: extractDir)
        return instance
    }

    private struct MrpackIndex: Codable {
        let name: String
        let dependencies: [String: String]
    }
}
