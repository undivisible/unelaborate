import Foundation

actor JavaAutoSelectService {
    func recommendedJavaVersion(for mcVersion: String) -> Int {
        let majorVersion = Int(mcVersion.split(separator: ".").dropFirst().first ?? "0") ?? 0
        if majorVersion >= 21 {
            return 21
        } else if majorVersion >= 18 {
            return 17
        } else if majorVersion >= 17 {
            return 17
        } else if majorVersion >= 16 {
            return 16
        } else {
            return 8
        }
    }

    func selectJavaPath(for instance: MinecraftInstance, available: [JVMInstall]) -> String? {
        let recommended = recommendedJavaVersion(for: instance.mcVersion)
        return available
            .filter { $0.javaVersion == recommended }
            .first?.path.path
            ?? available.max(by: { $0.javaVersion < $1.javaVersion })?.path.path
            ?? "/usr/bin/java"
    }
}
