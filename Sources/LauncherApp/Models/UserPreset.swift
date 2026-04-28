import Foundation

struct UserPreset: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var projectSlugs: [String]

    init(id: UUID = UUID(), name: String, description: String = "", projectSlugs: [String]) {
        self.id = id
        self.name = name
        self.description = description
        self.projectSlugs = projectSlugs
    }
}

actor PresetStore {
    private let rootURL: URL
    private let presetsURL: URL

    init(rootURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".unelaborate")) {
        self.rootURL = rootURL
        self.presetsURL = rootURL.appendingPathComponent("presets.json")
    }

    func load() throws -> [UserPreset] {
        if !FileManager.default.fileExists(atPath: presetsURL.path) {
            return []
        }
        let data = try Data(contentsOf: presetsURL)
        return try JSONDecoder().decode([UserPreset].self, from: data)
    }

    func save(_ presets: [UserPreset]) throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let data = try JSONEncoder.pretty.encode(presets)
        try data.write(to: presetsURL, options: .atomic)
    }
}
