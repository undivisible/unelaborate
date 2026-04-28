import Foundation

actor InstanceBackupService {
    func backup(instance: MinecraftInstance) throws -> URL {
        let backupsDir = instance.gameDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("backups")
        let target = backupsDir.appendingPathComponent("\(instance.name)-\(Int(Date().timeIntervalSince1970))")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)

        let items = try FileManager.default.contentsOfDirectory(at: instance.gameDirectory, includingPropertiesForKeys: nil)
        for item in items {
            let dest = target.appendingPathComponent(item.lastPathComponent)
            try FileManager.default.copyItem(at: item, to: dest)
        }

        return target
    }
}
