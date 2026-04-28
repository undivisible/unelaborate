import Foundation

actor InstallQueueService {
    private let downloader = DownloadService()
    private let cache = SharedCacheService()

    func install(resolved: [ResolvedInstall], into instance: MinecraftInstance) async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("unelaborate-install-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        var linkedFiles: [URL] = []

        do {
            for item in resolved {
                let expected = item.file.hashes["sha1"]
                let downloaded = try await downloader.download(url: item.file.url, expectedSha1: expected, into: tmp)
                let cached = try await cache.cacheFile(source: downloaded, type: item.type)

                let destinationDir: URL
                switch item.type {
                case .mod: destinationDir = instance.modsDirectory
                case .resourcepack: destinationDir = instance.resourcePackDirectory
                case .shader: destinationDir = instance.shaderDirectory
                case .modpack: destinationDir = instance.gameDirectory
                }

                let linked = try await cache.linkCachedFile(cached, into: destinationDir)
                linkedFiles.append(linked)
            }
        } catch {
            for linked in linkedFiles where FileManager.default.fileExists(atPath: linked.path) {
                try? FileManager.default.removeItem(at: linked)
            }
            throw error
        }
    }
}
