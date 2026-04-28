import Foundation

actor ModUpdateChecker {
    private let modrinth = ModrinthClient()

    func checkUpdates(for instance: MinecraftInstance) async -> [ModUpdate] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: instance.modsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        var updates: [ModUpdate] = []
        for file in files where file.pathExtension == "jar" {
            let slug = file.lastPathComponent.replacingOccurrences(of: ".jar", with: "")
            do {
                let versions = try await modrinth.versions(for: slug, loader: instance.loader, gameVersion: instance.mcVersion)
                if let latest = versions.first {
                    updates.append(ModUpdate(
                        projectSlug: slug,
                        currentFile: file.lastPathComponent,
                        latestVersion: latest.versionNumber,
                        latestFile: latest.files.first?.filename ?? ""
                    ))
                }
            } catch {
                continue
            }
        }
        return updates
    }
}

struct ModUpdate: Identifiable {
    let id = UUID()
    let projectSlug: String
    let currentFile: String
    let latestVersion: String
    let latestFile: String
}
