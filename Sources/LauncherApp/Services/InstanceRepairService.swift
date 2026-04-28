import Foundation

actor InstanceRepairService {
    func validate(instance: MinecraftInstance) async -> [RepairIssue] {
        var issues: [RepairIssue] = []

        let versionDir = instance.gameDirectory.appendingPathComponent("versions").appendingPathComponent(instance.mcVersion)
        let jarPath = versionDir.appendingPathComponent("\(instance.mcVersion).jar")
        if !FileManager.default.fileExists(atPath: jarPath.path) {
            issues.append(.init(severity: .critical, description: "Missing client jar", fix: .reinstallVersion))
        }

        let librariesDir = instance.gameDirectory.appendingPathComponent("libraries")
        if !FileManager.default.fileExists(atPath: librariesDir.path) {
            issues.append(.init(severity: .critical, description: "Missing libraries directory", fix: .reinstallVersion))
        }

        let assetsDir = instance.gameDirectory.appendingPathComponent("assets")
        if !FileManager.default.fileExists(atPath: assetsDir.path) {
            issues.append(.init(severity: .warning, description: "Missing assets directory", fix: .reinstallVersion))
        }

        let mods = (try? FileManager.default.contentsOfDirectory(at: instance.modsDirectory, includingPropertiesForKeys: nil)) ?? []
        let brokenMods = mods.filter { $0.pathExtension == "jar" && isJarBroken($0) }
        for mod in brokenMods {
            issues.append(.init(severity: .warning, description: "Corrupted mod: \(mod.lastPathComponent)", fix: .removeMod(mod)))
        }

        return issues
    }

    private func isJarBroken(_ url: URL) -> Bool {
        guard let archive = try? FileHandle(forReadingFrom: url) else { return true }
        let data = archive.readData(ofLength: 4)
        archive.closeFile()
        guard data.count == 4 else { return true }
        let signature = data.map { String(format: "%02x", $0) }.joined()
        return signature != "504b0304"
    }
}

struct RepairIssue: Identifiable {
    let id = UUID()
    let severity: RepairSeverity
    let description: String
    let fix: RepairFix
}

enum RepairSeverity: String {
    case critical
    case warning
}

enum RepairFix {
    case reinstallVersion
    case removeMod(URL)
}
