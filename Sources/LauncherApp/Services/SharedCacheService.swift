import Foundation

actor SharedCacheService {
    private let root: URL

    init(root: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".unelaborate/cache")) {
        self.root = root
    }

    func ensureDirectories() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for dir in ["mods", "resourcepacks", "shaderpacks", "versions", "libraries"] {
            try FileManager.default.createDirectory(at: root.appendingPathComponent(dir), withIntermediateDirectories: true)
        }
    }

    func cacheFile(source: URL, type: ModrinthProjectType) throws -> URL {
        try ensureDirectories()
        let folder: String
        switch type {
        case .mod: folder = "mods"
        case .modpack: folder = "mods"
        case .resourcepack: folder = "resourcepacks"
        case .shader: folder = "shaderpacks"
        }
        let destination = root.appendingPathComponent(folder).appendingPathComponent(source.lastPathComponent)
        if !FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.copyItem(at: source, to: destination)
        }
        return destination
    }

    func linkCachedFile(_ cachedFile: URL, into destinationDirectory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        let destination = destinationDirectory.appendingPathComponent(cachedFile.lastPathComponent)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        do {
            try FileManager.default.createSymbolicLink(at: destination, withDestinationURL: cachedFile)
        } catch {
            try FileManager.default.linkItem(at: cachedFile, to: destination)
        }
        return destination
    }
}
