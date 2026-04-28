import Foundation

actor CurseForgeModpackImportService {
    func importZip(from source: URL, into rootURL: URL) async throws -> MinecraftInstance {
        let extractDir = FileManager.default.temporaryDirectory.appendingPathComponent("cf-import-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = [source.path, "-d", extractDir.path]
        try process.run()
        process.waitUntilExit()

        let manifestPath = extractDir.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestPath)
        let manifest = try JSONDecoder().decode(CurseForgeManifest.self, from: manifestData)

        let name = manifest.name
        let version = manifest.minecraft.version
        let loader = manifest.minecraft.modLoaders.first?.id.split(separator: "-").first.map(String.init) ?? "vanilla"
        let loaderType = LoaderType(rawValue: loader) ?? .vanilla

        let instanceDir = rootURL.appendingPathComponent("instances").appendingPathComponent(name.replacingOccurrences(of: " ", with: "-").lowercased())
        let mods = instanceDir.appendingPathComponent("mods")
        let resourcepacks = instanceDir.appendingPathComponent("resourcepacks")
        let shaders = instanceDir.appendingPathComponent("shaderpacks")
        try FileManager.default.createDirectory(at: mods, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: resourcepacks, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: shaders, withIntermediateDirectories: true)

        let overridesDir = extractDir.appendingPathComponent("overrides")
        if FileManager.default.fileExists(atPath: overridesDir.path) {
            try copyContents(from: overridesDir, to: instanceDir)
        }

        let instance = MinecraftInstance(
            name: name,
            mcVersion: version,
            loader: loaderType,
            gameDirectory: instanceDir,
            modsDirectory: mods,
            resourcePackDirectory: resourcepacks,
            shaderDirectory: shaders
        )

        try FileManager.default.removeItem(at: extractDir)
        return instance
    }

    private func copyContents(from source: URL, to destination: URL) throws {
        let items = try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
        for item in items {
            let dest = destination.appendingPathComponent(item.lastPathComponent)
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: item, to: dest)
        }
    }
}

private struct CurseForgeManifest: Codable {
    let name: String
    let minecraft: CurseForgeMinecraft
}

private struct CurseForgeMinecraft: Codable {
    let version: String
    let modLoaders: [CurseForgeModLoader]

    enum CodingKeys: String, CodingKey {
        case version
        case modLoaders = "modLoaders"
    }
}

private struct CurseForgeModLoader: Codable {
    let id: String
    let primary: Bool
}
