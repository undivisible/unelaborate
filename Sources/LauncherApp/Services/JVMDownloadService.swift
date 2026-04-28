import Foundation

struct JVMInstall: Codable, Identifiable {
    let id: String
    let name: String
    let javaVersion: Int
    let path: URL
    let isDefault: Bool
}

actor JVMDownloadService {
    private let root: URL
    private let session: URLSession

    init(root: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".unelaborate/jvms")) {
        self.root = root
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 4
        self.session = URLSession(configuration: config)
    }

    func listInstalled() throws -> [JVMInstall] {
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }
        let dirs = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        return dirs.compactMap { dir in
            let javaBin = dir.appendingPathComponent("Contents/Home/bin/java")
            guard FileManager.default.fileExists(atPath: javaBin.path) else { return nil }
            let name = dir.lastPathComponent
            let version = javaVersion(from: dir)
            return JVMInstall(id: name, name: name, javaVersion: version, path: javaBin, isDefault: false)
        }
    }

    func installTemurin(version: Int) async throws -> JVMInstall {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let tag = "jdk-\(version)+35"
        let arch = getArch()
        let filename = "OpenJDK\(version)U-jdk_\(arch)_mac_hotspot_\(version)_35.tar.gz"
        let url = "https://github.com/adoptium/temurin\(version)-binaries/releases/download/\(tag)/\(filename)"

        let downloadDir = FileManager.default.temporaryDirectory.appendingPathComponent("unelaborate-jvm-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: downloadDir, withIntermediateDirectories: true)

        guard let remoteURL = URL(string: url) else { throw NSError(domain: "JVMDownloadService", code: 400) }
        let (data, _) = try await session.data(from: remoteURL)
        let tarPath = downloadDir.appendingPathComponent(filename)
        try data.write(to: tarPath)

        let extractDir = root.appendingPathComponent("temurin-\(version)")
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xzf", tarPath.path, "-C", extractDir.path, "--strip-components=1"]
        try process.run()
        process.waitUntilExit()

        try FileManager.default.removeItem(at: downloadDir)

        return JVMInstall(
            id: "temurin-\(version)",
            name: "Eclipse Temurin \(version)",
            javaVersion: version,
            path: extractDir.appendingPathComponent("Contents/Home/bin/java"),
            isDefault: false
        )
    }

    private func javaVersion(from path: URL) -> Int {
        let releaseFile = path.appendingPathComponent("Contents/Home/release")
        guard let content = try? String(contentsOf: releaseFile) else { return 0 }
        if let line = content.split(separator: "\n").first(where: { $0.hasPrefix("JAVA_VERSION=") }) {
            let versionString = line.replacingOccurrences(of: "JAVA_VERSION=\"", with: "").replacingOccurrences(of: "\"", with: "")
            let components = versionString.split(separator: ".")
            if components.count >= 2, let major = Int(components[0]), major == 1 {
                return Int(components[1]) ?? 0
            }
            return Int(components.first ?? "0") ?? 0
        }
        return 0
    }

    private func getArch() -> String {
        #if arch(arm64)
        return "aarch64"
        #else
        return "x64"
        #endif
    }
}
