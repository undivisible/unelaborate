import Foundation

actor QuiltInstaller {
    private let session = URLSession.shared

    func install(mcVersion: String, loaderVersion: String, into instance: MinecraftInstance) async throws {
        let url = URL(string: "https://meta.quiltmc.org/v3/versions/loader/\(mcVersion)/\(loaderVersion)/profile/json")!
        let (data, _) = try await session.data(from: url)
        let profile = try JSONDecoder().decode(QuiltProfile.self, from: data)

        let versionDir = instance.gameDirectory
            .appendingPathComponent("versions")
            .appendingPathComponent(profile.id)
        try FileManager.default.createDirectory(at: versionDir, withIntermediateDirectories: true)

        let jsonPath = versionDir.appendingPathComponent("\(profile.id).json")
        try data.write(to: jsonPath, options: .atomic)

        for library in profile.libraries {
            guard let artifact = library.downloads?.artifact else { continue }
            let libPath = instance.gameDirectory
                .appendingPathComponent("libraries")
                .appendingPathComponent(artifact.path)
            try FileManager.default.createDirectory(at: libPath.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: libPath.path) {
                let (libData, _) = try await session.data(from: URL(string: artifact.url)!)
                try libData.write(to: libPath)
            }
        }
    }
}

private struct QuiltProfile: Codable {
    let id: String
    let libraries: [QuiltLibrary]
}

private struct QuiltLibrary: Codable {
    let downloads: QuiltDownloads?
}

private struct QuiltDownloads: Codable {
    let artifact: QuiltArtifact?
}

private struct QuiltArtifact: Codable {
    let path: String
    let url: String
}
