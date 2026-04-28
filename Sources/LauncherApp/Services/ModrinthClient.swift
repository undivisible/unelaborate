import Foundation

actor ModrinthClient {
    private let base = URL(string: "https://api.modrinth.com/v2")!
    private let session: URLSession = .shared

    func search(query: String, type: ModrinthProjectType? = nil, loader: LoaderType? = nil, gameVersion: String? = nil) async throws -> [ModrinthProject] {
        var components = URLComponents(url: base.appendingPathComponent("search"), resolvingAgainstBaseURL: false)
        var items: [URLQueryItem] = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: "40")
        ]

        var facets: [String] = []
        if let type { facets.append("[\"project_type:\(type.rawValue)\"]") }
        if let loader { facets.append("[\"categories:\(loader.rawValue)\"]") }
        if let gameVersion { facets.append("[\"versions:\(gameVersion)\"]") }
        if !facets.isEmpty {
            let facetValue = "[\(facets.joined(separator: ","))]"
            items.append(URLQueryItem(name: "facets", value: facetValue))
        }

        components?.queryItems = items
        guard let url = components?.url else { return [] }

        var req = URLRequest(url: url)
        req.addValue("unelaborate-launcher/0.1", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode(ModrinthSearchResponse.self, from: data).hits
    }

    func versions(for project: String, loader: LoaderType, gameVersion: String) async throws -> [ModrinthVersionResponse] {
        let url = base
            .appendingPathComponent("project")
            .appendingPathComponent(project)
            .appendingPathComponent("version")

        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        comps?.queryItems = [
            URLQueryItem(name: "loaders", value: "[\"\(loader.rawValue)\"]"),
            URLQueryItem(name: "game_versions", value: "[\"\(gameVersion)\"]")
        ]

        guard let final = comps?.url else { return [] }
        var req = URLRequest(url: final)
        req.addValue("unelaborate-launcher/0.1", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode([ModrinthVersionResponse].self, from: data)
    }

    func getFeatured(type: ModrinthProjectType = .modpack) async throws -> [ModrinthProject] {
        var components = URLComponents(url: base.appendingPathComponent("search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "index", value: "relevance"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "facets", value: "[[\"project_type:\(type.rawValue)\"]]")
        ]

        guard let url = components?.url else { return [] }

        var req = URLRequest(url: url)
        req.addValue("unelaborate-launcher/0.1", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode(ModrinthSearchResponse.self, from: data).hits
    }
}
