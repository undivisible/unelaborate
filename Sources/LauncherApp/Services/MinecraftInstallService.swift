import CryptoKit
import Foundation

struct InstalledVersionArtifacts {
    let versionJSONPath: URL
    let clientJarPath: URL
    let mainClass: String
    let classpath: [URL]
    let assetIndexID: String
}

actor MinecraftInstallService {
    private let manifestURL = URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json")!
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 10
        session = URLSession(configuration: config)
    }

    func listVersions() async throws -> [VersionManifestEntry] {
        let (data, _) = try await session.data(from: manifestURL)
        let index = try JSONDecoder().decode(VersionManifestIndex.self, from: data)
        return index.versions
    }

    func installVersion(_ versionID: String, instance: MinecraftInstance) async throws -> InstalledVersionArtifacts {
        let versionsRoot = instance.gameDirectory.appendingPathComponent("versions")
        let versionRoot = versionsRoot.appendingPathComponent(versionID)
        let librariesRoot = instance.gameDirectory.appendingPathComponent("libraries")
        let assetsRoot = instance.gameDirectory.appendingPathComponent("assets")

        try FileManager.default.createDirectory(at: versionRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: librariesRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: assetsRoot, withIntermediateDirectories: true)

        let entries = try await listVersions()
        guard let entry = entries.first(where: { $0.id == versionID }), let versionURL = URL(string: entry.url) else {
            throw NSError(domain: "MinecraftInstallService", code: 404)
        }

        let (versionData, _) = try await session.data(from: versionURL)
        let versionManifest = try JSONDecoder().decode(MinecraftVersionManifest.self, from: versionData)

        let versionJSONPath = versionRoot.appendingPathComponent("\(versionID).json")
        try versionData.write(to: versionJSONPath, options: .atomic)

        let clientJarPath = versionRoot.appendingPathComponent("\(versionID).jar")
        try await downloadToFile(urlString: versionManifest.downloads.client.url, expectedSha1: versionManifest.downloads.client.sha1, destination: clientJarPath)

        var classpath: [URL] = [clientJarPath]
        let libraryDownloads = resolveLibraries(for: versionManifest)
        try await withThrowingTaskGroup(of: URL.self) { group in
            for artifact in libraryDownloads {
                group.addTask {
                    let destination = librariesRoot.appendingPathComponent(artifact.path)
                    try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try await self.downloadToFile(urlString: artifact.url, expectedSha1: artifact.sha1, destination: destination)
                    return destination
                }
            }

            for try await path in group {
                classpath.append(path)
            }
        }

        let indexesRoot = assetsRoot.appendingPathComponent("indexes")
        try FileManager.default.createDirectory(at: indexesRoot, withIntermediateDirectories: true)
        let assetIndexPath = indexesRoot.appendingPathComponent("\(versionManifest.assetIndex.id).json")
        let assetData = try await downloadToMemory(urlString: versionManifest.assetIndex.url, expectedSha1: versionManifest.assetIndex.sha1)
        try assetData.write(to: assetIndexPath, options: .atomic)

        let assetsObjectsRoot = assetsRoot.appendingPathComponent("objects")
        try FileManager.default.createDirectory(at: assetsObjectsRoot, withIntermediateDirectories: true)
        let assetIndexManifest = try JSONDecoder().decode(AssetIndexManifest.self, from: assetData)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for object in assetIndexManifest.objects.values {
                let hash = object.hash
                let prefix = String(hash.prefix(2))
                let destinationDir = assetsObjectsRoot.appendingPathComponent(prefix)
                let destination = destinationDir.appendingPathComponent(hash)
                if FileManager.default.fileExists(atPath: destination.path) { continue }

                group.addTask {
                    try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
                    let url = "https://resources.download.minecraft.net/\(prefix)/\(hash)"
                    try await self.downloadToFile(urlString: url, expectedSha1: hash, destination: destination)
                }
            }
            try await group.waitForAll()
        }

        return InstalledVersionArtifacts(
            versionJSONPath: versionJSONPath,
            clientJarPath: clientJarPath,
            mainClass: versionManifest.mainClass,
            classpath: classpath,
            assetIndexID: versionManifest.assetIndex.id
        )
    }

    private func resolveLibraries(for manifest: MinecraftVersionManifest) -> [LibraryArtifact] {
        manifest.libraries.compactMap { library in
            guard rulesAllow(rules: library.rules) else { return nil }
            return library.downloads?.artifact
        }
    }

    private func rulesAllow(rules: [VersionRule]?) -> Bool {
        guard let rules, !rules.isEmpty else { return true }

        var allowed = false
        for rule in rules {
            let osMatch = rule.os?.name == nil || rule.os?.name == "osx"
            if osMatch {
                allowed = (rule.action == "allow")
            }
        }
        return allowed
    }

    private func downloadToMemory(urlString: String, expectedSha1: String?) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "MinecraftInstallService", code: 400)
        }
        let (data, _) = try await session.data(from: url)
        if let expectedSha1 {
            let digest = Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard digest == expectedSha1.lowercased() else {
                throw NSError(domain: "MinecraftInstallService", code: 412)
            }
        }
        return data
    }

    private func downloadToFile(urlString: String, expectedSha1: String?, destination: URL) async throws {
        let data = try await downloadToMemory(urlString: urlString, expectedSha1: expectedSha1)
        try data.write(to: destination, options: .atomic)
    }
}
