import Foundation

actor InstanceStore {
    private let rootURL: URL
    private let manifestURL: URL

    init(rootURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".unelaborate")) {
        self.rootURL = rootURL
        self.manifestURL = rootURL.appendingPathComponent("instances.json")
    }

    func bootstrap() throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: manifestURL.path) {
            try Data("[]".utf8).write(to: manifestURL)
        }
    }

    func load() throws -> [MinecraftInstance] {
        try bootstrap()
        let data = try Data(contentsOf: manifestURL)
        return try JSONDecoder().decode([MinecraftInstance].self, from: data)
    }

    func save(_ instances: [MinecraftInstance]) throws {
        try bootstrap()
        let data = try JSONEncoder.pretty.encode(instances)
        try data.write(to: manifestURL, options: .atomic)
    }

    func createInstance(name: String, version: String, loader: LoaderType, group: String = "Default", notes: String = "") throws -> MinecraftInstance {
        try bootstrap()
        let sanitized = name.replacingOccurrences(of: " ", with: "-").lowercased()
        let base = rootURL.appendingPathComponent("instances").appendingPathComponent(sanitized)
        let mods = base.appendingPathComponent("mods")
        let resourcepacks = base.appendingPathComponent("resourcepacks")
        let shaders = base.appendingPathComponent("shaderpacks")
        try FileManager.default.createDirectory(at: mods, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: resourcepacks, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: shaders, withIntermediateDirectories: true)

        return MinecraftInstance(
            name: name,
            mcVersion: version,
            loader: loader,
            gameDirectory: base,
            modsDirectory: mods,
            resourcePackDirectory: resourcepacks,
            shaderDirectory: shaders,
            notes: notes,
            group: group
        )
    }
}

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return enc
    }
}
