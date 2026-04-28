import Foundation

enum CurseForgeError: Error {
    case missingAPIKey
}

actor CurseForgeClient {
    private let base = URL(string: "https://api.curseforge.com/v1")!
    private let session = URLSession.shared
    private let config = ConfigService()

    func searchMods(query: String, gameVersion: String, index: Int = 0, pageSize: Int = 25) async throws -> [CurseForgeMod] {
        let key = try await config.load().curseForgeAPIKey ?? ProcessInfo.processInfo.environment["CURSEFORGE_API_KEY"]
        guard let key, !key.isEmpty else { throw CurseForgeError.missingAPIKey }

        var components = URLComponents(url: base.appendingPathComponent("mods/search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "gameId", value: "432"),
            URLQueryItem(name: "classId", value: "6"),
            URLQueryItem(name: "searchFilter", value: query),
            URLQueryItem(name: "gameVersion", value: gameVersion),
            URLQueryItem(name: "index", value: String(index)),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]

        guard let url = components?.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue(key, forHTTPHeaderField: "x-api-key")

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(CurseForgeSearchResponse.self, from: data).data
    }

    func files(for modID: Int, gameVersion: String) async throws -> [CurseForgeFile] {
        let key = try await config.load().curseForgeAPIKey ?? ProcessInfo.processInfo.environment["CURSEFORGE_API_KEY"]
        guard let key, !key.isEmpty else { throw CurseForgeError.missingAPIKey }

        var components = URLComponents(url: base.appendingPathComponent("mods/\(modID)/files"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "gameVersion", value: gameVersion),
            URLQueryItem(name: "pageSize", value: "50")
        ]

        guard let url = components?.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue(key, forHTTPHeaderField: "x-api-key")

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(CurseForgeFilesResponse.self, from: data).data
    }
}
