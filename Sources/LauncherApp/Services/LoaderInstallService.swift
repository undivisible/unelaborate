import Foundation

struct LoaderInstallerResult {
    let loaderVersion: String
}

actor LoaderInstallService {
    private let session: URLSession = .shared

    func install(loader: LoaderType, mcVersion: String) async throws -> LoaderInstallerResult {
        switch loader {
        case .vanilla:
            return .init(loaderVersion: "vanilla")
        case .fabric:
            let url = URL(string: "https://meta.fabricmc.net/v2/versions/loader/\(mcVersion)")!
            let (data, _) = try await session.data(from: url)
            let rows = try JSONDecoder().decode([FabricLoaderRow].self, from: data)
            guard let first = rows.first else { throw NSError(domain: "LoaderInstallService", code: 404) }
            return .init(loaderVersion: first.loader.version)
        case .quilt:
            let url = URL(string: "https://meta.quiltmc.org/v3/versions/loader/\(mcVersion)")!
            let (data, _) = try await session.data(from: url)
            let rows = try JSONDecoder().decode([QuiltLoaderRow].self, from: data)
            guard let first = rows.first else { throw NSError(domain: "LoaderInstallService", code: 404) }
            return .init(loaderVersion: first.loader.version)
        case .neoforge:
            let url = URL(string: "https://maven.neoforged.net/api/maven/versions/releases/net/neoforged/neoforge")!
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(NeoForgeVersionResponse.self, from: data)
            guard let match = response.versions.first(where: { $0.contains(mcVersion.replacingOccurrences(of: ".", with: "")) }) ?? response.versions.first else {
                throw NSError(domain: "LoaderInstallService", code: 404)
            }
            return .init(loaderVersion: match)
        }
    }
}

private struct FabricLoaderRow: Codable {
    let loader: FabricLoaderInfo
}

private struct FabricLoaderInfo: Codable {
    let version: String
}

private struct QuiltLoaderRow: Codable {
    let loader: QuiltLoaderInfo
}

private struct QuiltLoaderInfo: Codable {
    let version: String
}

private struct NeoForgeVersionResponse: Codable {
    let versions: [String]
}
