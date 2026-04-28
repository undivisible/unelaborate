import Foundation

struct LauncherConfig: Codable {
    var curseForgeAPIKey: String?
}

actor ConfigService {
    private let configURL: URL

    init(rootURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".unelaborate")) {
        self.configURL = rootURL.appendingPathComponent("config.json")
    }

    func load() throws -> LauncherConfig {
        if !FileManager.default.fileExists(atPath: configURL.path) {
            return LauncherConfig(curseForgeAPIKey: nil)
        }
        let data = try Data(contentsOf: configURL)
        return try JSONDecoder().decode(LauncherConfig.self, from: data)
    }

    func save(_ config: LauncherConfig) throws {
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder.pretty.encode(config)
        try data.write(to: configURL, options: .atomic)
    }
}
