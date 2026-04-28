import Foundation

struct MinecraftServer: Codable, Identifiable {
    let id: UUID
    var name: String
    var address: String
    var port: Int
    var notes: String
    var lastJoined: Date?

    init(id: UUID = UUID(), name: String, address: String, port: Int = 25565, notes: String = "", lastJoined: Date? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.port = port
        self.notes = notes
        self.lastJoined = lastJoined
    }
}

actor ServerListService {
    private let rootURL: URL
    private let serversURL: URL

    init(rootURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".unelaborate")) {
        self.rootURL = rootURL
        self.serversURL = rootURL.appendingPathComponent("servers.json")
    }

    func load() throws -> [MinecraftServer] {
        if !FileManager.default.fileExists(atPath: serversURL.path) {
            return []
        }
        let data = try Data(contentsOf: serversURL)
        return try JSONDecoder().decode([MinecraftServer].self, from: data)
    }

    func save(_ servers: [MinecraftServer]) throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let data = try JSONEncoder.pretty.encode(servers)
        try data.write(to: serversURL, options: .atomic)
    }
}
