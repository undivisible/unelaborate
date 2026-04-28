import Foundation

actor NeoForgeInstaller {
    private let session = URLSession.shared

    func install(version: String, mcVersion: String, into instance: MinecraftInstance) async throws {
        let mavenUrl = "https://maven.neoforged.net/releases/net/neoforged/neoforge/\(version)/neoforge-\(version)-installer.jar"
        let installerDir = FileManager.default.temporaryDirectory.appendingPathComponent("neoforge-install-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: installerDir, withIntermediateDirectories: true)

        guard let url = URL(string: mavenUrl) else { throw NSError(domain: "NeoForgeInstaller", code: 400) }
        let (data, _) = try await session.data(from: url)
        let installerJar = installerDir.appendingPathComponent("installer.jar")
        try data.write(to: installerJar)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/java")
        process.arguments = [
            "-jar", installerJar.path,
            "--installClient", instance.gameDirectory.path
        ]
        process.currentDirectoryURL = installerDir
        try process.run()
        process.waitUntilExit()

        try FileManager.default.removeItem(at: installerDir)
    }
}
