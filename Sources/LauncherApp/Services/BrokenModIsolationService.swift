import Foundation

actor BrokenModIsolationService {
    func isolateAllMods(instance: MinecraftInstance, reason: String) throws -> URL {
        let quarantineRoot = instance.gameDirectory.appendingPathComponent("quarantine")
        let suffix = reason.replacingOccurrences(of: " ", with: "-")
        let target = quarantineRoot.appendingPathComponent("\(Int(Date().timeIntervalSince1970))-\(suffix)")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)

        let modFiles = (try? FileManager.default.contentsOfDirectory(at: instance.modsDirectory, includingPropertiesForKeys: nil)) ?? []
        for file in modFiles where file.pathExtension == "jar" || file.lastPathComponent.hasSuffix(".disabled") {
            let destination = target.appendingPathComponent(file.lastPathComponent)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: file, to: destination)
        }

        return target
    }
}
